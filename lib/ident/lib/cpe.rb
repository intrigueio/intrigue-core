module Intrigue
module Ident
class Cpe

  def initialize(cpe_string)
    @cpe = cpe_string
    x = _parse_cpe(@cpe)

    return nil unless x

    @vendor = x[:vendor]
    @product = x[:product]
    @version = x[:version]
    @variant = x[:variant] # TODO... currenty not used
  end

  def <(another)
    Gem::Version(@version) < Gem::Version(_parse_cpe(another[:version]))
  end

  def >(another)
    Gem::Version(@version) > Gem::Version(_parse_cpe(another[:version]))
  end

  # hacktastic! matches vulns by CPE
  def vulns

    # Set a data directory underneath our folder if we're not in the context of core
    if $intrigue_basedir
      nvd_data_directory = "#{$intrigue_basedir}/data/nvd"
    else
      nvd_data_directory = "#{File.expand_path('data/nvd', File.dirname(__FILE__))}"
    end

    # fail unless we have something to match
    return [] unless @version

    vulns = []
    files = [
        "#{nvd_data_directory}/nvdcve-1.0-2018.json",
        "#{nvd_data_directory}/nvdcve-1.0-2017.json",
        "#{nvd_data_directory}/nvdcve-1.0-2016.json",
        "#{nvd_data_directory}/nvdcve-1.0-2015.json",
        "#{nvd_data_directory}/nvdcve-1.0-2014.json",
        "#{nvd_data_directory}/nvdcve-1.0-2013.json",
        "#{nvd_data_directory}/nvdcve-1.0-2012.json",
        "#{nvd_data_directory}/nvdcve-1.0-2011.json"
      ]

    files.each do |f|
      puts "DEBUG Checking file: #{f}"
      next unless File.exist? f

      json = ::JSON.parse(File.open(f,"r").read)
      json["CVE_Items"].each do |v|

        # Note that the JSON has CVE stuff under a hash, so
        # pull that out separately (probably due to NVD responsibility vs Mitre)
        cve = v["cve"]

        # data sanity check
        unless cve["affects"] && cve["affects"]["vendor"] && cve["affects"]["vendor"]["vendor_data"]
          #puts "DEBUG No Affects data... #{cve["cve"]}"
          next
        end

        # check to make sure it includes our vendor
        vendors = cve["affects"]["vendor"]["vendor_data"].map{|x| x["vendor_name"].downcase }
        unless vendors.uniq.include? @vendor.downcase
          #vd = cve["affects"]["vendor"]["vendor_data"]
          #puts "DEBUG No vendor match: #{@vendor.downcase} in #{vendors.uniq.count} vendors..."
          next
        end

        # iterate through the heirarchy to get to product and version we can match on
        cve["affects"]["vendor"]["vendor_data"].each do |vd|
          #puts "DEBUG Checking Vendor Data #{vd}"
          vd["product"]["product_data"].each do |p|
            #puts "DEBUG Checking product #{p}"
            p["version"]["version_data"].each do |vd|
              next unless p["product_name"].downcase == @product.downcase
              #puts "DEBUG Matching: #{vd["version_value"]} with #{@version}"

              if vd["version_value"] >= @version
                #puts "MATCHED!"

                cve_id = cve["CVE_data_meta"]["ID"]
                #puts "CVE: #{cve_id}"

                # Get the CWE if we have it
                if cve["problemtype"] && cve["problemtype"]["problemtype_data"].first
                  cwe_id = cve["problemtype"]["problemtype_data"].first["description"].first["value"]
                  #puts "CWE: #{cwe_id}"
                end

                # Get the CVSS data if we have it
                if v["impact"]
                  cvss_v2_score = v["impact"]["baseMetricV2"]["cvssV2"]["baseScore"]
                  cvss_v2_vector = v["impact"]["baseMetricV2"]["cvssV2"]["vectorString"]
                  #puts "CVSS v2: #{cvss_v2}"

                  # v3 only goes back to 2016
                  if v["impact"]["baseMetricV3"]
                    cvss_v3_score = v["impact"]["baseMetricV3"]["cvssV3"]["baseScore"]
                    cvss_v3_vector = v["impact"]["baseMetricV3"]["cvssV3"]["vectorString"]
                    #puts "CVSS v3: #{cvss_v3}"
                  end
                end

                # create a hash with the vuln's data
                vuln = {
                  cve_id: cve_id,
                  cwe_id: cwe_id,
                  cvss_v2: {score: cvss_v2_score, vector: cvss_v2_vector },
                  cvss_v3: {score: cvss_v3_score, vector: cvss_v3_vector }
                }

                #puts "DEBUG Vuln: #{vuln}"

                vulns << vuln
              end

            end
          end
        end

      end
    end
    #puts "DEBUG Sending #{vulns.uniq.count} vulns"
  vulns.uniq
  end

  private

  def _parse_cpe(string)

    m = string.match(/^cpe:2.3:[o|a|s|h]:(.*?):.*$/)
    vendor = m[1] if m
    #puts "DEBUG Got Vendor: #{vendor}"
    m = string.match(/^cpe:2.3:[o|a|s|h]:.*?:(.*?):.*$/)
    product = m[1] if m
    #puts "DEBUG Got Product: #{product}"
    m = string.match(/^cpe:2.3:[o|a|s|h]:.*?:.*?:(.*)$/)
    version = m[1] if m
    #puts "DEBUG Got Version: #{version}"

    # if version has parens, only use the stuff priior (apache, nginx, etc)
    if version =~ /\(/
      old_version = version
      #puts "DEBUG Splitting Version: #{version}"

      version = old_version.split("(").first.chomp
      #puts "DEBUG New Version: #{version}"

      variant = old_version.split("(").last.split(")").first.chomp  #HACK
      #puts "DEBUG New Variant: #{variant}"

    end

    # if there's nothing to do here...
    return unless product && vendor && version

    # HACK... cleanup version if needed
    version = version.gsub(/\(.*/,"").gsub(/\+.*/,"").gsub(/-.*/,"").gsub(/\s.*/,"")

    parsed = {
      :vendor => vendor,
      :product => product,
      :version => version,
      :variant => variant
    }

  parsed
  end

end

end
end
