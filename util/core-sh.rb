#!/usr/bin/env ruby

require 'json'
require 'rest-client'

puts "Loading environment"
require_relative 'core'

###
### Define the prompt
###
prompt = "intrigue> "

def start_and_background(task_name,entity,options=nil)

  entity_type = entity.split("#").first
  entity_name = entity.split("#").last

  entity_hash = {
    :type => entity_type,
    :attributes => { :name => entity_name}
  }

  # Parse out options
  if options
    options_list = options.split(@delim).map do |option|
      { :name => option.split("=").first, :value => option.split("=").last }
    end
  end

  payload = {
    :task => task_name,
    :options => options_list,
    :entity => entity_hash
  }

  ###
  ### Send to the server
  ###

  task_id = RestClient.post "#{@server_uri}/task_runs", payload.to_json, :content_type => "application/json"
  #puts "#{@server_uri}/task_runs/#{task_id}" if task_id

  task_id
end

def help
  puts "Help me!"
end

# Handle the input
def handle_input(input)
  begin
    result = eval(input)
    puts("#{result}")
  rescue NameError
    puts "Unknown command"
  rescue ArgumentError => e
    puts "#{e}"
  end
end

# This is a lambda that runs the content of the block after the input is chomped.
repl = -> prompt do
  print prompt
  input = gets.chomp!
  puts "Command : #{input}"
  handle_input(input)
end

# After evaling and returning, fire up the prompt lambda again
loop do
  repl[prompt]
end
