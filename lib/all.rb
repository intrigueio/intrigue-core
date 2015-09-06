# System-level Initializers
require_relative 'initialize/hash'
require_relative 'initialize/string'

####
# Task-specific libraries
####
require_relative 'task_factory'

### Web & Parse mixins
require_relative 'tasks/helpers/web'
require_relative 'tasks/helpers/parse'

require_relative 'tasks/base'
current_folder = File.expand_path('../tasks', __FILE__) # get absolute directory
Dir["#{current_folder}/*.rb"].each {|f| require_relative f}

# Client libraries
require_relative 'client'

####
# Entity libraries
####
require_relative 'entity_factory' # base entity (must be required first)
entities_folder = File.expand_path('../entities', __FILE__) # get absolute directory
Dir["#{entities_folder}/*.rb"].each {|f| require_relative f}

####
# Scan Libraries
####
require_relative 'scans/base'
scanners_folder = File.expand_path('../scans', __FILE__) # get absolute directory
Dir["#{scanners_folder}/*.rb"].each {|f| require_relative f}

####
# Handler Libraries
####
require_relative 'handler_factory'
require_relative 'handler/base'
handlers_folder = File.expand_path('../handler', __FILE__) # get absolute directory
Dir["#{handlers_folder}/*.rb"].each {|f| require_relative f}
