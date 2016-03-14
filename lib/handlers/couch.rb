
module Intrigue
module Handler
  class Couch < Intrigue::Handler::Base

    def self.type
      "couch"
    end

    def process(result)
      require 'couchrest'

      # options
      # options[:server_uri]
      # options[:db_name]
      server = CouchRest.new  # assumes localhost by default!
      db = server.database!("test")  # create db if it doesn't already exist
      response = db.save_doc(
        "_id" => "#{result.id}",
        "unique_name" => _export_file_name(result),
        "version" => 1,
        "result" => result.export_hash)
    end
  end
end
end
