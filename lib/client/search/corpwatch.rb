require 'cgi'
require 'nokogiri'

module Intrigue
module Client
module Search
module Corpwatch

  # This class wraps the corpwatch Api
  class ApiClient

    include Intrigue::Task::Web

    def initialize(key)
      @api_key = key
    end

    #
    # Takes: Nothing
    #
    # Ruturns: An array of corpwatch corps from the search
    #
    def search(string)

      # Convert to a get-paramenter
      string = CGI.escapeHTML string.strip
      string.gsub!(" ", "%20")

      begin
        resp = JSON.parse(http_get_body(get_service_endpoint(@api_key, string)))
      rescue JSON::ParserError => e
        return nil
      end

      # Check for successful result
      return nil unless resp["meta"]["status"] == 200

      # initialize an array of corps to return
      corps = []

      # For each result, create a corp
      resp["result"]["companies"].each do |key, value|
        corps << Corpwatch::Corporation.new(value)
      end

    corps
    end

    def get_service_endpoint(key, company_name)
      "http://api.corpwatch.org/companies.json?company_name=#{company_name}&key=#{key}"
    end

  end

  # This class represents a corporation as returned by the Corpwatch service.
  class Corporation
    attr_accessor :cw_id
    attr_accessor :cik
    attr_accessor :name
    attr_accessor :irs_number
    attr_accessor :sic_code
    attr_accessor :industry_name
    attr_accessor :sic_sector
    attr_accessor :sector_name
    attr_accessor :source_type
    attr_accessor :address
    attr_accessor :country
    attr_accessor :state
    attr_accessor :top_parent_id
    attr_accessor :num_parents
    attr_accessor :num_children
    attr_accessor :max_year
    attr_accessor :min_year

    #
    #  Takes: An xml doc representing a corpwatch corporation
    #
    #  Returns: Nothing
    #
    def initialize(hash)
      @cw_id = hash["cw_id"]
      @cik = hash["cik"]
      @name = hash["company_name"]
      @irs_number = hash["irs_number"]
      @sic_code = hash["sic_code"]
      @industry = hash["industry_name"]
      @sic_sector = hash["sic_sector"]
      @sector_name = hash["sector_name"]
      @source_type = hash["source_type"]
      @address = hash["raw_address"]
      @country = hash["country_code"]
      @state = hash["subdiv_code"]
      @top_parent_id = hash["top_parent_id"]
      @num_parents = hash["num_parents"]
      @num_children = hash["num_children"]
      @max_year = hash["max_year"]
      @min_year = hash["min_year"]
    end

    def to_s
      "#{@company_name}: #{@address} #{@state} #{@country}"
    end

  end
end
end
end
end