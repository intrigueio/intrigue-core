
###
### SYSTEM HELPERS (for use everywhere)
###

# Intrigue System-wide Bootstrap
require_relative 'system/bootstrap'
include Intrigue::Core::System::Bootstrap

# Intrigue System-wide Match Exeptions
require_relative 'system/match_exceptions'
include Intrigue::Core::System::MatchExceptions

# Intrigue System-wide Validations 
require_relative 'system/validations'
include Intrigue::Core::System::Validations

# Intrigue System-wide Helpers (both app and backend) 
require_relative 'system/helpers'
include Intrigue::Core::System::Helpers

# Intrigue System-wide Helpers (both app and backend) 
require_relative 'system/dns_helpers'
#include Intrigue::Core::System::DnsHelpers

# Intrigue Export Format
require_relative 'system/json_data_export_file'

###
### END SYSTEM HELPERS
###


####
# Task-specific libraries
####
require_relative 'intrigue-tasks'

###
### TODO ... load in default workflows here 
### 

# Client libraries
require_relative 'client'

####
# Entity Libraries
####
require_relative 'entity_factory'
require_relative 'entity_manager'

# Load all .rb file in lib/entities by default
entities_folder = File.expand_path('../entities', __FILE__) # get absolute directory
require_relative "#{entities_folder}/network_service" # have to do this first, since others dep on it
Dir["#{entities_folder}/*.rb"].each {|f| require_relative f}

####
# Issue Libraries
####
require_relative 'intrigue-issues'
issues_folder = File.expand_path('../issues', __FILE__) # get absolute directory
Dir["#{issues_folder}/*.rb"].each {|f| require_relative f}

#  note that all specific issues are sourced in via this file (for reasons described in that file)

####
# Handler Libraries
####

# require handler-specifics here
require 'faraday_middleware'
require 'elasticsearch'

###
require_relative 'handler_factory'
require_relative 'handlers/base'
handlers_folder = File.expand_path('../handlers', __FILE__) # get absolute directory
Dir["#{handlers_folder}/*.rb"].each {|f| require_relative f}


####
# Notifier Libraries
####
require_relative 'notifier_factory'
require_relative 'notifiers/base'
notifiers_folder = File.expand_path('../notifiers', __FILE__) # get absolute directory
Dir["#{notifiers_folder}/*.rb"].each {|f| require_relative f}

###
### User-specified directories
###
# And check to see if there are any specified load paths

if Intrigue::Core::System::Config.config["intrigue_load_paths"]
  Intrigue::Core::System::Config.config["intrigue_load_paths"].each do |load_path|
    load_path = "#{load_path}" unless load_path[0] == "/"

    Dir["#{load_path}/entities/*.rb"].each do |file|
      #puts "Adding user entity from: #{file}"
      require_relative file
    end

    Dir["#{load_path}/handlers/*.rb"].each do |file|
      #puts "Adding user handler from: #{file}"
      require_relative file
    end

    Dir["#{load_path}/issues/*.rb"].each do |file|
      #puts "Adding user notifier from: #{file}"
      require_relative file
    end

    Dir["#{load_path}/notifiers/*.rb"].each do |file|
      #puts "Adding user notifier from: #{file}"
      require_relative file
    end

    Dir["#{load_path}/tasks/*.rb"].each do |file|
      #puts "Adding user task from: #{file}"
      require_relative file
    end

  end
end

###
# load in any private checks if they're available, fail silently if not
###
begin
  require 'intrigue-ident-private'
rescue LoadError => e 
  # unable to load gem, presumably unavailable
end

###
# load in any private tasks if they're available, fail silently if not
###
begin
  require 'intrigue-core-private'
rescue LoadError => e 
  # unable to load gem, presumably unavailable
end

###
# load in ruclei if available, fail silently if not
###
begin
  require 'ruclei'
rescue LoadError => e 
  # unable to load gem, presumably unavailable
end