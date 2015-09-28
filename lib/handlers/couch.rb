require 'couchrest'

module Intrigue
module Handler
  class Couch < Intrigue::Handler::Base

    def self.type
      "couch"
    end

    def process(result, options={})

      # options
      # options[:server_uri]
      # options[:db_name]

      return "Unable to handle #{result}" unless result.kind_of? Intrigue::Model::TaskResult

      server = CouchRest.new  # assumes localhost by default!
      db = server.database!("test")  # create db if it doesn't already exist
      response = db.save_doc(
        "_id" => "#{result.id}",
        "unique_name" => "#{result.task_name}_#{result.entity.attributes["name"].gsub("/","")}",
        "version" => 1,
        "result" => result.export_hash)
    end
  end
end
end
