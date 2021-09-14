module Intrigue
  module Task
    module VulnDb

      #
      # This method assumes we get a list of objects with a CPE we can parse
      # and use for a vuln lookup based on the configured methdo
      #
      def add_vulns_by_cpe(component_list)

        # Make sure the key is set before querying intrigue api
        begin
          intrigueio_api = _get_task_config "intrigueio_api_hostname"
          intrigueio_api_key = _get_task_config "intrigueio_api_key"
          use_api = true
        rescue MissingTaskConfigurationError
          use_api = false
        end

        # for ech fingerprint, map vulns
        component_list = component_list.map do |fp|
          next unless fp

          vulns = []
          if fp["type"] == "fingerprint" && fp["inference"]
            cpe = Intrigue::VulnDb::Cpe.new(fp["cpe"])
            if use_api # get vulns via intrigue API
              _log "Matching vulns for #{fp["cpe"]} via Intrigue API"
              vulns = cpe.query_intrigue_vulndb_api(intrigueio_api, intrigueio_api_key)
            else
              vulns = cpe.query_local_nvd_json
            end

            # merge it in
            fp.merge!({"vulns" => vulns })
          else
            _log "Inference disallowed on: #{fp["cpe"]}" if fp["cpe"]
            _log "Returning un-enriched fps"
            fp if fp["type"] == "fingerprint"
          end

        end

      component_list.compact
      end

    end
  end
end

module Intrigue
module VulnDb

  class Cpe
    include Intrigue::Task::Web

    def initialize(cpe_string)

      @cpe = cpe_string

      x = _parse_cpe(@cpe)
      return nil unless x

      @vendor = x[:vendor]
      @product = x[:product]
      @version = x[:version]
      @update = x[:update]

    end

    def query_intrigue_vulndb_api(api_host, api_key)

      #puts "Querying VulnDB API!"
      #puts "https://api.intrigue.io/api/vulndb/match/#{@vendor}/#{@product}/#{@version}"

      begin
        uri = "#{api_host}/api/vulndb/match_cpe/#{@cpe}"
        uri << "?key=#{api_key}"

        puts "Requesting Vulns for CPE: #{@cpe}"

        response = http_request :get, uri

        # if the API is down, we'll get a nil response, so handle that case gracefully
        return [] unless response

        result = JSON.parse(response.body_utf8)

        # return our normal hash
      rescue JSON::ParserError => e
      end
    result || []
    end

    # hacktastic! matches vulns by CPE
    def query_local_nvd_json

      # Set a data directory underneath our folder if we're not in the context of core
      if $intrigue_basedir
        nvd_data_directory = "#{$intrigue_basedir}/data/nvd"
      else
        nvd_data_directory = "#{File.expand_path('data/nvd', File.dirname(__FILE__))}"
      end

      # fail unless we have something to match
      return [] unless @version

      vulns = []
      matched = []
      # TODO.. should be last 3-4 years... (dependent on memory req)
      files = [
          "#{nvd_data_directory}/nvdcve-1.0-2019.json",
          "#{nvd_data_directory}/nvdcve-1.0-2018.json",
          "#{nvd_data_directory}/nvdcve-1.0-2017.json",
          "#{nvd_data_directory}/nvdcve-1.0-2016.json"
        ]

      files.each do |file|
        #puts "DEBUG Checking file: #{f}"
        next unless File.exist? file

        # open and read the file
        f = File.open(file,"r")
        json = JSON.parse(f.read)
        # free memory
        f.close

        json["CVE_Items"].each do |v|

          # Note that the JSON has CVE stuff under a hash, so
          # pull that out separately

          # data sanity check, no affects data, no continue
          unless v["cve"]["affects"] && v["cve"]["affects"]["vendor"] && v["cve"]["affects"]["vendor"]["vendor_data"]
            next
          end

          # check to make sure it includes our vendor
          vendors = v["cve"]["affects"]["vendor"]["vendor_data"].map{|x| x["vendor_name"].downcase }
          next unless vendors.uniq.include? @vendor.downcase

          # iterate through the heirarchy to get to product and version we can match on
          v["cve"]["affects"]["vendor"]["vendor_data"].each do |vd|
            next if matched.include? v["cve"]["CVE_data_meta"]["ID"] # skip if we got it already

            vd["product"]["product_data"].each do |p|
              next if matched.include? v["cve"]["CVE_data_meta"]["ID"] # skip if we got it already

              p["version"]["version_data"].each do |vd|
                next if matched.include? v["cve"]["CVE_data_meta"]["ID"] # skip if we got it already
                next unless p["product_name"].downcase == @product.downcase
                #puts "DEBUG Matching: #{vd["version_value"]} with #{@version}"

                # first make sure we share the same major version
                next unless  vd["version_value"].split(".").first == @version.split(".").first

                # if so, check that this affects versions equal to or newer than uors
                vuln_version = ::Versionomy.parse(vd["version_value"])
                our_version = ::Versionomy.parse(@version)

                if vuln_version >= our_version
                  puts "VulnDB DEBUG - VULN MATCHED (#{v["cve"]['CVE_data_meta']['ID']}): #{Versionomy.parse(vd['version_value'])} >= #{Versionomy.parse(@version)}}!"
                  matched << v["cve"]["CVE_data_meta"]["ID"]
                  cve_id = v["cve"]["CVE_data_meta"]["ID"]
                  puts "VulnDB DEBUG - got CVE: #{cve_id}"

                  # Get the CWE if we have it
                  if v["cve"]["problemtype"] && v["cve"]["problemtype"]["problemtype_data"].first
                    cwe_id = v["cve"]["problemtype"]["problemtype_data"].first["description"].first["value"]
                    puts "VulnDB DEBUG - got CWE: #{cwe_id}"
                  end

                  # Get the CVSS data if we have it
                  if v["impact"]

                    cvss_v2 = v["impact"]["baseMetricV2"]["cvssV2"]
                    cvss_v2_score = v["impact"]["baseMetricV2"]["cvssV2"]["baseScore"]
                    cvss_v2_vector = v["impact"]["baseMetricV2"]["cvssV2"]["vectorString"]

                    # v3 only goes back to 2016
                    if v["impact"]["baseMetricV3"]
                      cvss_v3 = v["impact"]["baseMetricV3"]["cvssV3"]
                      cvss_v3_score = v["impact"]["baseMetricV3"]["cvssV3"]["baseScore"]
                      cvss_v3_vector = v["impact"]["baseMetricV3"]["cvssV3"]["vectorString"]
                    end
                  end

                  # create a hash with the vuln's data, matches "slim" export from the
                  # vulndb server
                  vuln = {
                    cve: cve_id,
                    cwe: cwe_id,
                    cvss_v2_score: cvss_v2_score,
                    cvss_v3_score: cvss_v3_score,
                    auth: (cvss_v2 && cvss_v2["cvssV2"] ? !(cvss_v2["cvssV2"]["authentication"] == "NONE") : nil )
                  }

                  vulns << vuln
                end

              end
            end
          end
        end
      end

      #puts "DEBUG Sending #{vulns.uniq.count} vulns"
      json = nil

    vulns.uniq
    end

    private

    def _parse_cpe(string)

      m = string.match(/^cpe:2.3:[o|a|s|h]:(.*?):(.*?):(.*?):(.*?)$/)
      return nil unless m

      vendor = "#{m[1]}".strip
      product = "#{m[2]}".strip
      version = "#{m[3]}".strip
      update = "#{m[4]}".strip

      # if version has parens, only use the stuff priior (apache, nginx, etc)
      if version.match(/\(/)
        old_version = version
        puts "DEBUG Splitting Version: #{version}"

        version = old_version.split("(").first.chomp
        puts "DEBUG New Version: #{version}"

      #  update = old_version.split("(").last.split(")").first.chomp  #HACK
      #  #puts "DEBUG New Variant: #{variant}"

      end

      # if there's nothing to do here...
      #return unless product && vendor && version

      # HACK... cleanup version if needed
      version = "#{version}".gsub(/\(.*/,"").gsub(/\+.*/,"").gsub(/-.*/,"").gsub(/\s.*/,"")

      parsed = {
        :vendor => vendor,
        :product => product,
        :version => version,
        :update => update
      }

    parsed
    end
  end

end
end
