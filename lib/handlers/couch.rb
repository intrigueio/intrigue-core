require 'couchrest'

module Intrigue
module Handler
  class Couch < Intrigue::Handler::Base

    def self.type
      "couch"
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      return "Unable to process" unless result.respond_to? export_hash

      server = CouchRest.new  # assumes localhost by default!
      database = _get_handler_config("database")
      db = server.database!(database || "test" )  # create db if it doesn't already exist
      response = db.save_doc(
        "_id" => "#{result.id}",
        "unique_name" => "#{prefix_name}#{result.name}",
        "version" => 1,
        "result" => result.export_hash
      )

    end
  end
end
end
