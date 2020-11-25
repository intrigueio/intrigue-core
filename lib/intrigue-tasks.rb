####
### These /should/ always be availble 
###
require 'base64'
require 'date'
require 'digest'
require 'ident'
require 'json'
require 'net/http'
require 'resolv'
require 'socket'
require 'tempfile'
require 'thread'
require 'uri'
require 'webrick'

###
### These may / may not be available so let's wrap them  
###
### In the case where we're a gem, they're not yet available. add them as deps
###
begin  # try to load runtime deps
  
  require 'aws-sdk-route53'
  require 'aws-sdk-s3'
  require 'aws-sdk-sqs'
  require 'censys'
  require 'cloudflare'
  require 'compare-xml'
  require 'digest'
  require 'dnsruby'
  require 'dnsimple'
  require 'em-resolv-replace'
  require 'flareon'
  require 'ip_ranger'
  require 'ipaddr'
  require 'maxminddb'
  require 'net-http2'
  require 'net/dns'
  require 'net/ftp'
  require 'neutrino_api'
  require 'nmap/xml'
  require 'nokogiri'
  require 'open3'
  require 'open-uri'
  require 'opencorporates'
  require 'openssl'
  require 'ostruct'
  require 'resolv-replace'
  require 'rexml/document'
  require 'snmp'
  require 'spidr'
  require 'towerdata_api'
  require 'typhoeus'
  require 'versionomy'
  require 'whois'
  require 'whois-parser'
  require 'whoisology'
  require 'zip'

rescue LoadError => e 
  puts "ERROR! Unable to load a dep, functionality may be limited: #{e}"
end

###
### Task factory: Standardize the creation and validation of tasks
###
module Intrigue
  class TaskFactory
  
    def self.register(klass)
      @tasks = [] unless @tasks
      @tasks << klass
    end
  
    def self.list
      @tasks
    end
  
    def self.allowed_tasks_for_entity_type(entity_type)
      @tasks.select {|task_class| task_class if task_class.metadata[:allowed_types].include? entity_type}
    end
    #
    # XXX - can :name be set on the class vs the object
    # to prevent the need to call "new" ?
    #
    def self.include?(name)
      @tasks.each do |t|
        if (t.metadata[:name] == name)
          return true
        end
      end
    false
    end
  
    #
    # XXX - can :name be set on the class vs the object
    # to prevent the need to call "new" ?
    #
    def self.create_by_name(name)
      @tasks.each do |t|
        if (t.metadata[:name] == name)
          return t.new # Create a new object and send it back
        end
      end
      ### XXX - exception handling? This should return a specific exception.
      raise "No task with the name: #{name}!"
    end
  
    #
    # XXX - can :name be set on the class vs the object
    # to prevent the need to call "new" ?
    #
    def self.create_by_pretty_name(pretty_name)
      @tasks.each do |t|
        if (t.metadata[:pretty_name] == pretty_name)
          return t.new # Create a new object and send it back
        end
      end
  
      ### XXX - exception handling? Should this return an exception?
      raise "No task with the name: #{name}!"
    end
  
  end
end
  
# system helpers
system_folder = File.expand_path('../system', __FILE__) # get absolute directory
Dir["#{system_folder}/*.rb"].each { |file| require_relative file }

### Mixins with common task functionality
require_relative 'tasks/helpers/generic'
require_relative 'tasks/helpers/web'
tasks_folder = File.expand_path('../tasks/helpers', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load all discovery tasks
require_relative 'tasks/base'
tasks_folder = File.expand_path('../tasks', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load enrichment functfions
tasks_folder = File.expand_path('../tasks/enrich', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load import tasks
tasks_folder = File.expand_path('../tasks/import', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load vuln check tasks
tasks_folder = File.expand_path('../tasks/threat', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load vuln check tasks
tasks_folder = File.expand_path('../tasks/vuln', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }