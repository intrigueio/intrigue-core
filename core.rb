require 'sinatra'
require 'yaml'

require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'
require 'redis'
require 'timeout'

# Core libraries
require_relative 'lib/all'

# Core tasks
require_relative 'tasks/all'

require 'json'
require 'rest-client'

# Debug
require 'pry'

###
### START CONFIG MANAGEMENT
###

###
### XXX - this is not threadsafe :(
###
$intrigue_global_timeout = 900
$intrigue_basedir = File.dirname(__FILE__)

# Check to see if the config exists
config_file = "#{$intrigue_basedir}/config/config.yml"
if File.exist? config_file

  # Okay, so we have a file
  $intrigue_config = YAML.load_file(config_file)

  # Check to make sure we have an engine_id config
  if $intrigue_config[:engine_id] == "XXX" or $intrigue_config[:engine_id] == ""

    # we need to generate it
    $intrigue_config[:engine_id] = SecureRandom.uuid

  end

else  # No config exists

  # Create a blank config
  $intrigue_config = {}

  # Create the Engine ID
  $intrigue_config[:engine_id] = SecureRandom.uuid

end

# Regardless, write our config back to the file
File.open("#{$intrigue_basedir}/config/config.yml", 'w') do |f|
  f.write $intrigue_config.to_yaml
end

###
### END CONFIG MANAGEMENT
###

set :views, "#{$intrigue_basedir}/views"
set :public_folder, 'public'

#Setup redis for resque
$intrigue_redis = Redis.new

#Application version
$intrigue_version = "0.1.6"

before do
  $intrigue_server_uri = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
end

not_found do
  "Unable to find this content."
end

helpers do

  def h(text)
    Rack::Utils.escape_html(text)
  end

end


get '/version' do
  $intrigue_version
end

#
# Main Page
#
get '/' do
  stats = Sidekiq::Stats.new
  @failed = stats.failed
  @processed = stats.processed
  @queues = stats.queues
  @tasks = TaskFactory.list.map{|x| x.send(:new)}
  @task_names = @tasks.map{|t| t.metadata[:pretty_name]}.sort
  erb :index
end

#
# Export All Tasks
#
get '/tasks.json' do
  tasks = []
  TaskFactory.list.each do |t|
      tasks << t.send(:new).metadata
  end
tasks.to_json
end

#
# Export a single task
#
get '/tasks/:id.json' do
  task_name = params[:id]
TaskFactory.create_by_name(task_name).metadata.to_json
end

#
# Export All Data
#
get '/task_runs.json' do

  # Clear all results
  namespace = "result"
  keys = $intrigue_redis.keys("#{namespace}*")

  results = []
  keys.each do |key|
    results << $intrigue_redis.get(key)
  end

  ### XXX - SECURITY - this needs to be escaped, or the individual
  ### results need to have their fields escaped. Noodle.
  results.to_json
end

#
# Existing task runs
#
get '/task_runs' do
  namespace = "result"
  keys = $intrigue_redis.keys("#{namespace}*")

  unsorted_results = []
  keys.each do |key|
    unsorted_results << JSON.parse($intrigue_redis.get(key))
  end

  @results = unsorted_results.sort_by{ |k| k["timestamp_start"] }.reverse

  erb :task_runs
end


#
# Get rid of all existing task runs
#
get '/task_runs/clear' do

  # Clear all results
  namespace = "result"
  keys = $intrigue_redis.keys "#{namespace}*"
  $intrigue_redis.del keys unless keys == []

  # Clear the default queue
  Sidekiq::Queue.new.clear

  # Beam me up, scotty!
  redirect '/'
end

###
# Helper to construct the request when the application is used interactively
###
post '/interactive' do

  # Generate a task id
  task_id = SecureRandom.uuid

  # This is some pretty dark magic. We need to convert form inputs into a reasonable
  # request. This means collecting attributes and options and arranging them
  # in way that the application can handle. Prepare yourself.

  # Construct the attributes hash from the parameters. Loop through each of the
  # parameters looking for things that look like attributes, and add them to our
  # attribs hash
  attribs = {}
  @params.each do |name,value|
    #puts "Looking at #{name} to see if it's an attribute"
    if name =~ /^attrib/
      attribs["#{name.gsub("attrib_","")}"] = "#{value}"
    end
  end

  # Construct an entity from the data we have
  entity = { :type => @params["entity_type"], :attributes => attribs }


  # Construct the options hash from the parameters
  options = []
  @params.each do |name,value|
    #puts "Looking at #{name} to see if it's an option"
    if name =~ /^option/
      options << {
                  "name" => "#{name.gsub("option_","")}",
                  "value" => "#{value}"
                  }
    end
  end


  # Reconstruct the request as a hash, which we'll send to ourself as an API
  # request (as json). When we're using in interactive mode, we'll hardcode the
  # webhook so that we post back to ourselves
  x = { "task" => @params["task"],
        "options" => options,
        "entity" => entity,
        "hook_uri" => "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/task_runs/#{task_id}"
  }

  puts "making request with #{x}"

  start_task_run(task_id, x)

  redirect "/task_runs/#{task_id}"
end


#
# Create a task run
#
post '/task_runs' do

  # Generate a task id
  task_id = SecureRandom.uuid

  @params = JSON.parse(request.body.read) if request.content_type == "application/json"

  # Taks the parameters and turn them into a task_run request
  task_run_info = @params

  # Sensible default if the hook URI not specified (this is the case with most CLI stuff including core-cli)
  local_hook = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/task_runs/#{task_id}"
  task_run_info["hook_uri"] = local_hook unless task_run_info["hook_uri"]

  ###
  ### XXX SECURITY
  ###
  ### Do some upfront sanity checking of the user parameters
  ###
  return "Invalid Task name!" unless TaskFactory.include?(task_run_info["task"])

  # Start the task _run
  start_task_run task_id, task_run_info

  # Return a task id so the caller can store and look up results later
task_id
end


###
# Accept the results of a task run (webhook POSTs here by default)
###
post '/task_runs/:id' do

  # Retrieve the request's body and parse it as JSON
  result = JSON.parse(request.body.read)

  # Do something with event_json
  #puts "Got result:\n #{result}"
  job_id = result["id"]

  # Persist the result
  $intrigue_redis.set("result:#{job_id}", result.to_json)

  # Return status
  status 200 if result
end

#
# Get the results of a task run
#
get "/task_runs/:id.json" do
  content_type :json
  result = $intrigue_redis.get("result:#{params[:id]}")
  result if result
end

#
# Show the results in a human readable format
#
get '/task_runs/:id' do
  # Get the result from Redis
  result = $intrigue_redis.get("result:#{params[:id]}")

  if result # Assuming it's available, display it
    @task_run = JSON.parse(result)
    erb :task_run
  else # Otherwise tell the user to wait
    "Not available yet. (Please refresh)"
  end
end



# Determine if the task run is complete
#
get '/task_runs/:id/complete' do
  result = "false"
  if $intrigue_redis.get("result:#{params[:id]}")
    result = "true"
  end
result
end


###
# NEWS!
###
get '/news/?' do
  erb :news
end

###
# TEST!
###

#
# Show the results in a human readable format
#
get '/task_runs/:id/viz' do
  # Get the result from Redis
  #result = $intrigue_redis.get("result:#{params[:id]}")

  #if result # Assuming it's available, display it
    #@task_run = JSON.parse(result)
    @task_id = params[:id]
    erb :task_run_viz
  #else # Otherwise tell the user to wait
  #  "Not available yet"
  #end
end

###
### Helpers
###



####
#### Helper method for starting a task run
####
def start_task_run(task_id, task_run_info)

  ###
  # XXX - Need to parse out the entity we want to pass to our tasks
  ###
  task_name = task_run_info["task"] ## Task name
  task_options = task_run_info["options"] ## || [{"name" => "count", "value" => 100 }]
  entity = task_run_info["entity"]  ## || {:type => "Host", :attributes => {:name => "8.8.8.8"}}
  webhook_uri = task_run_info["hook_uri"]

  ###
  # XXX - Create the task
  ###
  task = TaskFactory.create_by_name(task_name)

  unless entity
    entity = task.metadata[:example_entities].first
  end

  # Sending untrusted input in, so make sure we sanity check!
  jid = task.class.perform_async task_id, entity, task_options, "webhook", webhook_uri
end
