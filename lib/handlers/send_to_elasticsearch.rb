
###
###
###
module Intrigue
  module Core
  module Handler

  class SendToElasticsearch < Intrigue::Core::Handler::Base

    SLICE_SIZE = 250

    def self.metadata
      {
        :name => "send_to_elasticsearch",
        :pretty_name => "Send to ElasticSearch",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      return "Unable to process" unless result.respond_to? "export_json"

      puts "Uploading entities to Elasticsearch!"
      host = _get_handler_config("host")
      port = _get_handler_config("port")
      user = _get_handler_config("user")
      pass = _get_handler_config("pass")
      scheme = _get_handler_config("scheme")

      es = ElasticsearchClient.new(host,port,user,pass,scheme)

      # upload entities
      result.entities.each_slice(SLICE_SIZE) do |slice|
        es.store_bulk_slice_of_type(slice, "entities-#{result.name}")
      end

      # upload issues
      result.issues.each_slice(SLICE_SIZE) do |slice|
        es.store_bulk_slice_of_type(slice, "issues-#{result.name}")
      end

    end
  end

  class ElasticsearchClient

    def initialize(host,port,user=nil,pass=nil,scheme=nil)
      @es_host = host
      @es_port = port
      @es_user = user
      @es_pass = pass
      @es_scheme = scheme || "http"
    end

    def client

      Elasticsearch::Client.new({
        hosts:
        [
           {
             host: @es_host || "localhost",
             port: @es_port || "9200",
             user: @es_user,
             password: @es_pass,
             scheme: @es_scheme
           }
        ]
      })

    end

    def store_bulk_slice_of_type(slice, index_name)

      # then store it!
      begin
        response = client.bulk body: slice_to_bulk_json(slice, index_name)
        puts "Got errors in bulk response:#{JSON.pretty_generate(response)}" if response["errors"]
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
        puts "ERROR! Bad Request sending to ElasticSearch: #{e}"
      rescue Elasticsearch::Transport::Transport::Error => e
        puts "ERROR! Unable to connect to ElasticSearch: #{e}"
      end
    end

    private

    ##
    ## helper method to convert a set of entities/issues/whatever will support .to_hash
    ## into elasticsearch's bulk_json format
    def slice_to_bulk_json(item_slice, index_name="entities")

      ### conver tot format
      bulk_list = []
      item_slice.each do |i|
        # two lines per
        # https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-gsg-upload-data.html
        bulk_list << {"index" => { "_id" => i.id, "_index" => index_name}}
        bulk_list << i.to_hash
      end

      # return the bulk request we're going to make
      out = bulk_list.map{|x| x.to_json }

    "#{out.join("\n") }" << "\n"
    end

  end

  end
  end
  end