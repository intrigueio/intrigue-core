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
  end

  def <(another)
    Gem::Version(@version) < Gem::Version(_parse_cpe(another[:version]))
  end

  def >(another)
    Gem::Version(@version) > Gem::Version(_parse_cpe(another[:version]))
  end

  # hacktastic! matches vulns by CPE
  def vulns
    return unless @version
    vulns = []
    files = [
        "#{$nvd_data_directory}/nvdcve-1.0-2018.json",
        "#{$nvd_data_directory}/nvdcve-1.0-2017.json",
        "#{$nvd_data_directory}/nvdcve-1.0-2016.json" ]
      #      "#{basedir}/../data/nvd/nvdcve-1.0-2015.json",
      #      "#{basedir}/../data/nvd/nvdcve-1.0-2014.json",
      #      "#{basedir}/../data/nvd/nvdcve-1.0-2013.json",
      #      "#{basedir}/../data/nvd/nvdcve-1.0-2012.json",
      #      "#{basedir}/../data/nvd/nvdcve-1.0-2011.json",
      #      "#{basedir}/../data/nvd/nvdcve-1.0-2010.json"]

    files.each do |f|
      #puts "Checking file: #{f}"
      next unless File.exist? f
      json = ::JSON.parse(File.open(f,"r").read)
      json["CVE_Items"].each do |v|
        v = v["cve"]

        # data sanity check
        unless v["affects"] && v["affects"]["vendor"] && v["affects"]["vendor"]["vendor_data"]
          #puts "DEBUG No Affects data... #{v["cve"]}"
          next
        end

        # check to make sure it includes our vendor
        vendors = v["affects"]["vendor"]["vendor_data"].map{|x| x["vendor_name"].downcase }
        unless vendors.uniq.include? @vendor.downcase
          #vd = v["affects"]["vendor"]["vendor_data"]
          #puts "DEBUG No vendor match: #{@vendor.downcase} in #{vendors.uniq.count} vendors..."
          next
        end

        # iterate through the heirarchy to get to product and version we can match on
        v["affects"]["vendor"]["vendor_data"].each do |vd|
          #puts "DEBUG Checking Vendor Data #{vd}"
          vd["product"]["product_data"].each do |p|
            #puts "DEBUG Checking product #{p}"
            p["version"]["version_data"].each do |vd|
              next unless p["product_name"].downcase == @product.downcase
              #puts "DEBUG Matching: #{vd["version_value"]} with ##{@version}"
              vulns << v if vd["version_value"] >= @version
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
    #puts "Got Vendor: #{vendor}"
    m = string.match(/^cpe:2.3:[o|a|s|h]:.*?:(.*?):.*$/)
    product = m[1] if m

    m = string.match(/^cpe:2.3:[o|a|s|h]:.*?:.*?:(.*)$/)
    version = m[1] if m

    # if there's nothing to do here...
    return unless product && vendor && version

    # HACK... cleanup version if needed
    version = version.gsub(/\(.*/,"").gsub(/\+.*/,"").gsub(/-.*/,"").gsub(/\s.*/,"")

    parsed = {
      :vendor => vendor,
      :product => product,
      :version => version
    }

  parsed
  end

end

end
end
