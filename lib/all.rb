# System-level Initializers
require_relative 'initialize/hash'
require_relative 'initialize/string'

require_relative 'log'

####
# Task-specific libraries
####
require_relative 'task_factory'
require_relative 'task/task_log'

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

# all other entities
entities_folder = File.expand_path('../../entities', __FILE__) # get absolute directory
Dir["#{entities_folder}/*.rb"].each {|f| require_relative f}

####
# Scan Libraries
####
require_relative 'scan/scan_log.rb'
require_relative 'scan/base.rb'
require_relative 'scan/simple_scan.rb'
