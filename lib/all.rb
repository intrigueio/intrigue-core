
# System-level Initializers
require_relative 'initialize/hash'
require_relative 'initialize/string'

####
# Task-specific libraries
####
require_relative 'task_factory'

### Mixins with common task functionality
require_relative 'tasks/helpers/generic'
require_relative 'tasks/helpers/lists'
require_relative 'tasks/helpers/parse'
require_relative 'tasks/helpers/scanner'
require_relative 'tasks/helpers/web'

# Load all .rb file in lib/tasks by default
require_relative 'tasks/base'
tasks_folder = File.expand_path('../tasks', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# And check to see if there are any specified load paths
global_config = Intrigue::Config::GlobalConfig.new
if global_config.config["intrigue_task_load_paths"]
  global_config.config["intrigue_task_load_paths"].each do |load_path|
    load_path = "#{tasks_folder}/#{load_path}" unless load_path[0] == "/"
    Dir["#{load_path}/*.rb"].each do |file|
      puts "Adding file from load path (#{load_path}: #{file}"
      require_relative file
    end
  end
end

# Client libraries
require_relative 'client'

####
# Entity libraries
####
entities_folder = File.expand_path('../entities', __FILE__) # get absolute directory
Dir["#{entities_folder}/*.rb"].each {|f| require_relative f}

####
# Scan Libraries
####
require_relative 'scan_factory'

require_relative 'scans/base'
scanners_folder = File.expand_path('../scans', __FILE__) # get absolute directory
Dir["#{scanners_folder}/*.rb"].each {|f| require_relative f}

####
# Handler Libraries
####
require_relative 'handler_factory'
require_relative 'handlers/base'
handlers_folder = File.expand_path('../handlers', __FILE__) # get absolute directory
Dir["#{handlers_folder}/*.rb"].each {|f| require_relative f}
