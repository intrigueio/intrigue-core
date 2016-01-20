require 'rspec/core'
require 'rspec/core/rake_task'

#task :default => :spec

desc "System Setup"
task :setup do
  require 'fileutils'

  puts "Setup initiated!"

  # Setup
  intrigue_basedir = File.dirname(__FILE__)

  ## Copy system config into place
  system_config_file = "#{intrigue_basedir}/config/config.json"
  if File.exist? system_config_file
    puts "File exists: #{system_config_file}"
  else
    puts "Creating.... #{system_config_file}"
    FileUtils.cp "#{system_config_file}.default", system_config_file
  end

  ## Copy database config into place
  database_config_file = "#{intrigue_basedir}/config/database.yml"
  if File.exist? database_config_file
    puts "File exists: #{database_config_file}"
  else
    puts "Creating.... #{database_config_file}"
    FileUtils.cp "#{database_config_file}.default", database_config_file
  end

  ## Copy sidekiq config into place
  sidekiq_config_file = "#{intrigue_basedir}/config/sidekiq.yml"
  if File.exist? sidekiq_config_file
    puts "File exists: #{sidekiq_config_file}"
  else
    puts "Creating.... #{sidekiq_config_file}"
    FileUtils.cp "#{sidekiq_config_file}.default", sidekiq_config_file
  end

end

desc "Run Database Migrations"
task :migrate => :setup do

  begin
    require 'yaml'
    require 'json'
    require 'dm-core'
    require 'dm-migrations'

    intrigue_basedir = File.dirname(__FILE__)
    config_file = "#{intrigue_basedir}/config/config.json"

    begin
      system_config = JSON.parse File.read(config_file)
    rescue JSON::ParserError => e
      puts "Fatal! Unable to read #{config_file}"
      return
    end

    database_config = YAML.load_file("#{intrigue_basedir}/config/database.yml")
    database_environment = "#{system_config["intrigue_environment"]["value"]}"

    unless database_config[database_environment]
      puts "FATAL! Unable to read database configuration"
      return
    end

    Dir["#{intrigue_basedir}/app/models/*.rb"].each { |file| require_relative file }

    # Run our setup with the correct enviroment
    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, database_config[database_environment])
    DataMapper.auto_migrate!
  rescue Exception => e
    puts "Error... Unable to migrate: #{e}"
  end
end

desc "Run Specs"
task :spec do
end

desc "Run Integration Specs (requires API running)"
task :integration do
  t.rspec_opts = "--pattern spec/integration/*_spec.rb"
end
