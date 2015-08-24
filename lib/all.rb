# System-level Initializers
require_relative 'initialize/hash'
require_relative 'initialize/string'

####
# Task-specific libraries
####
require_relative 'task_factory'

### Web & Parse mixins
require_relative 'task/web'
require_relative 'task/parse'

# Client libraries
require_relative 'client'

####
# Entity libraries
####
require_relative 'entity_factory'

# base entity (must be required first)
require_relative '../entities/base'
entities_folder = File.expand_path('../../entities', __FILE__) # get absolute directory
Dir["#{entities_folder}/*.rb"].each {|f| require_relative f}

####
# Scan Libraries
####
scanners_folder = File.expand_path('../scan', __FILE__) # get absolute directory
Dir["#{scanners_folder}/*.rb"].each {|f| require_relative f}

####
# Report Libraries
####
require_relative 'report_factory'
report_handlers_folder = File.expand_path('../report/handler', __FILE__) # get absolute directory
Dir["#{report_handlers_folder}/*.rb"].each {|f| require_relative f}
