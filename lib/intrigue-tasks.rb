###
### These task-specific gems may / may not be available so let's wrap them
###
### In the case where we're a gem, they're not yet available. add them as deps
###
begin  # try to load runtime deps
  require 'aws-sdk-iam'
  require 'aws-sdk-ecs'
  require 'aws-sdk-ec2'
  require 'aws-sdk-route53'
  require 'aws-sdk-s3'
  require 'aws-sdk-sqs'
  require 'censys'
  require 'cloudflare'
  require 'compare-xml'
  require 'csv'
  require 'digest'
  require 'dnsruby'
  require 'dnsimple'
  require 'google_search_results'
  require 'flareon'
  require 'ip_ranger'
  require 'ipaddr'
  require 'net-http2'
  require 'net/dns'
  require 'net/ftp'
  require 'neutrino_api'
  require 'nmap/xml'
  require 'nokogiri'
  require 'octokit'
  require 'open3'
  require 'open-uri'
  require 'opencorporates'
  require 'openssl'
  require 'ostruct'
  require 'rex'
  require 'rex/sslscan'
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
  require 'zetalytics'
rescue LoadError => e
  puts "ERROR! Unable to load a dep, functionality may be limited: #{e}"
end

# system helpers
system_folder = File.expand_path('../system', __FILE__) # get absolute directory
Dir["#{system_folder}/*.rb"].each { |file| require_relative file }

require_relative 'all_base'

# Load all discovery tasks
tasks_folder = File.expand_path('../tasks', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load enrichment functions
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

# Load all checks
tasks_folder = File.expand_path('../checks', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load bruteforce tasks
tasks_folder = File.expand_path('../tasks/vuln/bruteforce', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }