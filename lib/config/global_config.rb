require 'json'

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
        config = JSON.parse File.read(@config_file)

        # load up the default config file
        default_config = JSON.parse File.read("#{@config_file}.default")

        # merge them
        @config = default_config.deep_merge config
      end

      def save
        json_config = JSON.pretty_generate(@config)
        File.open("#{@config_file}","w").write(json_config)
      end

    end
  end
end
