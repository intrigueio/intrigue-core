# System-level Initializers
require_relative 'initialize/hash'
require_relative 'initialize/string'

####
# Task-specific libraries
####
require_relative 'task_factory'
require_relative 'task_helper'
require_relative 'task_log'

### Web is used by many of the other libraries, so we load it here first
require_relative 'task/web'

### Parsers
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
