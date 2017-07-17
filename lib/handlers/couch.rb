require 'couchrest'

module Intrigue
module Handler
  class Couch < Intrigue::Handler::Base

    def self.type
      "couch"
    end

    def process(result)
      
      return "Unable to process" unless result.respond_to? export_hash

      server = CouchRest.new  # assumes localhost by default!
      db = server.database!("test")  # create db if it doesn't already exist
      response = db.save_doc(
        "_id" => "#{result.id}",
        "unique_name" => _export_file_name(result),
        "version" => 1,
        "result" => result.export_hash
      )

    end
  end
end
end
