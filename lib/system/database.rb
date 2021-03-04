require 'sequel'

module Intrigue
module Core
module System
  module Database

  ## no need to namespace?

  # database set up
  def setup_database
    database_config = YAML.load_file("#{$intrigue_basedir}/config/database.yml")
    options = {
      :max_connections => database_config[$intrigue_environment]["max_connections"] || 20,
      :pool_timeout => database_config[$intrigue_environment]["pool_timeout"] || 240
    }

    #
    # Allow the database to be configured via ENV var or our config file, or fall back
    # to a sensible default
    database_host = ENV["DB_HOST"] || database_config[$intrigue_environment]["host"] || "localhost"
    database_port = ENV["DB_PORT"] || database_config[$intrigue_environment]["port"] || 5432
    database_user = ENV["DB_USER"] || database_config[$intrigue_environment]["user"] || "intrigue"
    database_pass = ENV["DB_PASS"] || database_config[$intrigue_environment]["password"]
    database_name = ENV["DB_NAME"] || database_config[$intrigue_environment]["database"] || "intrigue_dev"
    database_debug = ENV["DB_DEBUG"] || database_config[$intrigue_environment]["debug"]

    if $intrigue_environment != "test"

      if database_pass
        postgres_connect_string = "postgres://#{database_user}:#{database_pass}@#{database_host}:#{database_port}/#{database_name}"
      else # handle the case where we're configured to postgres TRUST auth
        postgres_connect_string = "postgres://#{database_user}@#{database_host}:#{database_port}/#{database_name}"
      end

      #puts "Connecting to Postgres at: #{postgres_connect_string}"
      $db = ::Sequel.connect(postgres_connect_string, options)

      # Allow data to be stored / queryed in JSON format
      $db.extension :pg_json
      Sequel.extension :pg_json_ops
    
      # Allow datasets to be paginated
      $db.extension :pagination

    else
      sqlite_test_string = "sqlite://#{$intrigue_basedir}/data/test.db"
      puts "TEST! Connecting to Sqlite at: #{sqlite_test_string}"
      $db = ::Sequel.connect("#{sqlite_test_string}")
    end

    $db.loggers << ::Logger.new($stdout) if database_debug

    Sequel.extension :migration, :core_extensions
    ::Sequel::Model.plugin :update_or_create
  end

  end
end
end
end