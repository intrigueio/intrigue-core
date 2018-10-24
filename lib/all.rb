# Task-related Gems
require 'aws-sdk-sqs'
require 'aws-sdk-s3'
require 'censys'
require 'digest'
require 'dnsruby'
require 'eventmachine'
require 'geoip'
require 'ipaddr'
require 'json'
require 'net/dns'
require 'net/http'
require 'nmap/xml'
require 'nokogiri'
require 'open-uri'
require 'opencorporates'
require 'openssl'
require 'resolv'
require 'resolv-replace'
require 'rexml/document'
require 'snmp'
require 'socket'
require 'spidr'
require 'tempfile'
require 'thread'
require 'towerdata_api'
require 'uri'
require 'whois'
require 'whois-parser'
require 'whoisology'
require 'yomu'

# Intrigue System Management
require_relative 'system'

####
# ident (currently local, in /lib/ident)
####
require 'intrigue-ident'

####
# Task-specific libraries
####
require_relative 'task_factory'

### Mixins with common task functionality
require_relative 'tasks/helpers/generic'
tasks_folder = File.expand_path('../tasks/helpers', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load all discovery tasks
require_relative 'tasks/base'
tasks_folder = File.expand_path('../tasks', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load control tasks
tasks_folder = File.expand_path('../tasks/control', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load import tasks
tasks_folder = File.expand_path('../tasks/import', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load vuln check tasks
tasks_folder = File.expand_path('../tasks/vulns', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load enrichment functfions
tasks_folder = File.expand_path('../tasks/enrich', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# And check to see if there are any specified load paths
global_config = $global_config
if global_config.config["intrigue_task_load_paths"]
  global_config.config["intrigue_task_load_paths"].each do |load_path|
    load_path = "#{tasks_folder}/#{load_path}" unless load_path[0] == "/"
    Dir["#{load_path}/*.rb"].each do |file|
      puts "Adding user task: #{file}"
      require_relative file
    end
  end
end

####
## Machines
####
require_relative 'machine_factory'
require_relative 'machines/base'
machines_folder = File.expand_path('../machines', __FILE__) # get absolute directory
Dir["#{machines_folder}/*.rb"].each {|f| require_relative f}

# And check to see if there are any specified load paths
global_config = $global_config
if global_config.config["intrigue_machine_load_paths"]
  global_config.config["intrigue_machine_load_paths"].each do |load_path|
    load_path = "#{machines_folder}/#{load_path}" unless load_path[0] == "/"
    Dir["#{load_path}/*.rb"].each do |file|
      puts "Adding user machine: #{file}"
      require_relative file
    end
  end
end


# Client libraries
require_relative 'client'

####
# Entity-specific libraries
####
require_relative 'entity_manager'

# Load all .rb file in lib/entities by default
entities_folder = File.expand_path('../entities', __FILE__) # get absolute directory
require_relative "#{entities_folder}/network_service" # have to do this first, since others dep on it
Dir["#{entities_folder}/*.rb"].each {|f| require_relative f}

# And check to see if there are any specified load paths
global_config = $global_config
if global_config.config["intrigue_entity_load_paths"]
  global_config.config["intrigue_entity_load_paths"].each do |load_path|
    load_path = "#{entities_folder}/#{load_path}" unless load_path[0] == "/"
    Dir["#{load_path}/*.rb"].each do |file|
      puts "Adding user entity: #{file}"
      require_relative file
    end
  end
end

####
# Handler Libraries
####
require_relative 'handler_factory'
require_relative 'handlers/base'
handlers_folder = File.expand_path('../handlers', __FILE__) # get absolute directory
Dir["#{handlers_folder}/*.rb"].each {|f| require_relative f}

# And check to see if there are any specified load paths
global_config = $global_config
if global_config.config["intrigue_handler_load_paths"]
  global_config.config["intrigue_handler_load_paths"].each do |load_path|
    load_path = "#{handlers_folder}/#{load_path}" unless load_path[0] == "/"
    Dir["#{load_path}/*.rb"].each do |file|
      puts "Adding user handler: #{file}"
      require_relative file
    end
  end
end

####
# Notifier Libraries
####
require_relative 'notifier_factory'
require_relative 'notifiers/base'
notifiers_folder = File.expand_path('../notifiers', __FILE__) # get absolute directory
Dir["#{notifiers_folder}/*.rb"].each {|f| require_relative f}

# And check to see if there are any specified load paths
global_config = $global_config
if global_config.config["intrigue_notifier_load_paths"]
  global_config.config["intrigue_notifier_load_paths"].each do |load_path|
    load_path = "#{notifiers_folder}/#{load_path}" unless load_path[0] == "/"
    Dir["#{load_path}/*.rb"].each do |file|
      puts "Adding user notifier: #{file}"
      require_relative file
    end
  end
end
