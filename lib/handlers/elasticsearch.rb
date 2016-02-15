require 'elasticsearch'
require 'typhoeus/adapters/faraday'

module Intrigue
module Handler
  class Elasticsearch < Intrigue::Handler::Base

    def self.type
      "elasticsearch"
    end

    def process(result, options)

      username = _get_handler_config("username")
      password = _get_handler_config("password")
      hostname = _get_handler_config("hostname")

      url = "https://#{username}:#{password}@#{hostname}:443"
      index = "task_results"
      type = "task_result"

      client = ::Elasticsearch::Client.new(url: url)
      client.index(index: index, type: type, body: result.export_json)
    end

  end
end
end
