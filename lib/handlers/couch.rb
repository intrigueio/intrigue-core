require 'couchrest'

module Intrigue
module Handler
  class Couch < Intrigue::Handler::Base

    def self.type
      "couch"
    end

    def process(result, name=nil)

      return "Unable to process" unless result.respond_to? export_hash

      server = CouchRest.new  # assumes localhost by default!
      db = server.database!("test")  # create db if it doesn't already exist
      response = db.save_doc(
        "_id" => "#{result.id}",
        "unique_name" => "#{name || result.name}",
        "version" => 1,
        "result" => result.export_hash
      )

    end
  end
end
end
