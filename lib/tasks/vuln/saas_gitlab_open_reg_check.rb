module Intrigue
  module Task
  class SaasGitlabOpenRegCheck < BaseTask

    def self.metadata
      {
        :name => "vuln/saas_gitlab_open_reg_check",
        :pretty_name => "Gitlab Open Registration Check",
        :authors => ["jcran"],
        :description => "Checks to see if a gitlab system allows registration for a given domain or org",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["Uri"],
        :example_entities => [
          {"type" => "String", "details" => {"name" => "https://intrigue.io"}}
        ],
        :allowed_options => [],
        :created_types => []
      }
    end

    ## Default method, subclasses must override this
    def run
      super

      require_enrichment

      url = _get_entity_name

      # first, ensure we're enriched / fingerprinted
      @entity = require_enrichment
      fingerprint = _get_entity_detail("fingerprint")

      # then check and make sure we're gitlab
      if is_product?(fingerprint, "Gitlab")

        # now check for registration
        check_for_open_reg url

      else
        _log_error "Unable to fingerprint as Gitlab, failing"
      end

    end

    def check_for_open_reg(url)

      # grab the page
      body = http_get_body(url)

      if body =~ /href=\"\#register-pane\"/
        _create_linked_issue("open_gitlab_registration", {
          proof: {
            response_body: body
          }
        })
      end

    end

  end
  end
  end
