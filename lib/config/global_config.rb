require 'json'
require 'fileutils'
require 'tempfile'
###
### Global Config Management
###
module Intrigue
  module Config

    class GlobalConfig

      attr_accessor :config

      def initialize
        @config = {}
        @config_file = "#{$intrigue_basedir}/config/config.json"

        # load up the config file (if it exists)
        f = File.open(@config_file,"r")
        config = JSON.parse(f.read)
        f.close

        # load up the default config file
        f = File.open("#{@config_file}.default","r")
        default_config = JSON.parse(f.read)
        f.close

        # merge them
        @config = default_config.deep_merge config
        save
      end

      def save
        # Generate the JSON and move to the config file location
        # Use safe_write since there are other processes using the config
        # file at the same time we're writing it (TODO.. handle this...)
        json_config = JSON.pretty_generate(@config)
        safe_write "#{@config_file}", json_config
      end

      def safe_write(path, content)
        # Create a tempfile and write to it
        temp_file = Tempfile.new 'config'
        File.open(temp_file, 'w+') do |f|
          f.write(content)
        end
        # move it to the correct location
        FileUtils.mv temp_file, path
      end

    end
  end
end
