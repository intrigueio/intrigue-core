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
      server = CouchRest.new  # assumes localhost by default!
      db = server.database!("test")  # create db if it doesn't already exist
      response = db.save_doc(
        "_id" => "#{result.id}",
        "unique_name" => "#{result.task_name}_#{result.base_entity.name.gsub("/","")}",
        "version" => 1,
        "result" => result.export_hash)
    end
  end
end
end
