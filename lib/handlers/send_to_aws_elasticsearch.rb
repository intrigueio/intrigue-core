require 'faraday_middleware/aws_sigv4'

module Intrigue
module Core
module Handler
  class SendToAwsElasticsearch < Intrigue::Core::Handler::Base

    def self.metadata
      {
        :name => "send_to_aws_elasticsearch",
        :pretty_name => "Send to AWS ElasticSearch",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      return "Unable to process" unless result.respond_to? "export_json"
      
      puts "Uploading entities to AWS Elasticsearch!"
      client = elasticsearch_client

      # upload entities
      index_name = "#{prefix_name}#{result.name}-entities"
      result.entities.paged_each(rows_per_fetch: 100) do |e|
        begin
          puts "Uploading entity #{e.type_string} #{e.name}"
          client.index index: index_name, id: e.uuid, body: e.short_details.to_json
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest => ex
          puts "ERROR Uploading entity #{e.type_string} #{e.name}"
        end
      end

      # upload issues
      index_name = "#{prefix_name}#{result.name}-issues"
      result.issues.paged_each(rows_per_fetch: 100) do |i|
        begin
          puts "Uploading issue #{i.name}"
          client.index index: index_name, id: i.uuid, body: i.export_json  
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest => ex
          puts "ERROR Uploading issue #{i.name}"
        end
      end

    end
  
    def elasticsearch_client
      
      endpoint = _get_handler_config("aws_endpoint")
      region = _get_handler_config("aws_region")
      access_key = _get_handler_config("aws_access_key")
      secret_key = _get_handler_config("aws_secret_key")
      
      client = Elasticsearch::Client.new(url: endpoint, port: 443) do |f|
        f.request :aws_sigv4,
          service: "es",
          region: region,
          access_key_id: access_key,
          secret_access_key: secret_key
      end
      
    client
    end
  
    #def to_bulk_json(entities_slice)
    #
    #  bulk_list = []
    #  entities_slice.each do |e|
    #    # two lines per
    #    # https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-gsg-upload-data.html
    #    bulk_list << {"index" => { "_id" => e.uid, "_index" => @index}}
    #    bulk_list << e.to_hash
    #  end
    #  
    #"#{bulk_list.map{|x| x["timestamp"] = nil; x.to_json}.join("\n")}" << "\n"
    #end




  end
end
end
end