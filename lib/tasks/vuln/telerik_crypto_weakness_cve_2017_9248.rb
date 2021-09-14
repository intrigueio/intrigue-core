module Intrigue
module Task
class TelerikCryptoWeaknessCve20179248 < BaseTask

  def self.metadata
    {
      :name => "vuln/telerik_crypto_weakness_cve_2017_9248",
      :pretty_name => "Vuln Check - Telerik Crypto Weakness (CVE-2017-9248)",
      :authors => ["jcran"],
      :identifiers => [{ "cve" =>  "CVE-2017-9248" }],
      :description => "Check for vulnerability CVE-2017-9248",
      :references => [
        "https://captmeelo.com/pentest/2018/08/03/pwning-with-telerik.html"
      ],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    require_enrichment
    
    # check our fingerprints for a version
    our_version = nil
    fp = _get_entity_detail("fingerprint")
    fp.each do |f|
      if f["product"] == "Sitefinity" && f["version"]
        our_version = f["version"]
        break
      end
    end
    
    if our_version
      _log "Got version: #{our_version}"
    else 
      _log_error "Unable to get version, failing"
      return 
    end

    # check the web ui uploader 
    web_ui_uri = "#{_get_entity_name}/Telerik.Web.UI.DialogHandler.aspx"
    web_ui_response = http_get_body(web_ui_uri)

    if web_ui_response =~ /Loading the dialog.../
      _log "Checking version against known vulnerable versions"

      if ::Versionomy.parse(our_version) <= ::Versionomy.parse("10.0.6412.0")
        _log_good "Vulnerable!"
        _create_linked_issue("telerik_crypto_weakness_cve_2017_9248", {
          proof: {
            detected_version: our_version
          }
        })
        return 
      end 
      
    end

    _log "Not vulnerable!"
  end

  def first_body_capture(text, regex)
    x = text.match(regex)
    if x && x.captures
      x = x.captures.first.strip
      filter.each{|f| x.gsub!(f,"") }
      x = x.strip
      return x if x && x.length > 0
    end
  nil
  end

=begin
  def vulnerable_versions
    '2007.1423
    2007.1521
    2007.1626
    2007.2101
    2007.21107
    2007.2918
    2007.31218
    2007.31314
    2007.31425
    2008.1415
    2008.1515
    2008.1619
    2008.21001
    2008.2723
    2008.2826
    2008.31105
    2008.31125
    2008.31314
    2009.1311
    2009.1402
    2009.1527
    2009.2701
    2009.2826
    2009.31103
    2009.31208
    2009.31314
    2010.1309
    2010.1415
    2010.1519
    2010.2713
    2010.2826
    2010.2929
    2010.31109
    2010.31215
    2010.31317
    2011.1315
    2011.1413
    2011.1519
    2011.2712
    2011.2915
    2011.3.1305
    2011.31115
    2012.1.215
    2012.1.411
    2012.2.607
    2012.2.724
    2012.2.912
    2012.3.1016
    2012.3.1205
    2012.3.1308
    2013.1.220
    2013.1.403
    2013.1.417
    2013.2.611
    2013.2.717
    2013.3.1015
    2013.3.1114
    2013.3.1324
    2014.1.225
    2014.1.403
    2014.2.618
    2014.2.724
    2014.3.1024
    2015.1.204
    2015.1.225
    2015.1.401
    2015.2.604
    2015.2.623
    2015.2.729
    2015.2.826
    2015.3.1111
    2015.3.930
    2016.1.113
    2016.1.225
    2016.2.504
    2016.2.607
    2016.3.1018
    2016.3.1027
    2016.3.914
    2017.1.118
    2017.1.228
    2017.2.503
    2017.2.621
    2017.2.711
    2017.3.913'.split("\n")
  end
=end

end
end
end