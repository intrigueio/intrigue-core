module Intrigue
module Handler
  class Elasticsearch < Intrigue::Handler::Base

    def self.type
      "elasticsearch"
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      return "Unable to process" unless result.respond_to? "export_json"

      require 'elasticsearch'
      require 'typhoeus/adapters/faraday'

      username = _get_handler_config("username")
      password = _get_handler_config("password")
      hostname = _get_handler_config("hostname")

      url = "https://#{username}:#{password}@#{hostname}:443"
      index = "#{prefix_name}#{result.name}"
      type = "task_result"

      client = ::Elasticsearch::Client.new(url: url)
      client.index(index: index, type: type, body: result.export_json)
    end

  end
end
end
