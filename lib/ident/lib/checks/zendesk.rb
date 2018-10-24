module Intrigue
module Ident
module Check
    class Zendesk < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "service",
            :vendor =>"Zendesk",
            :product =>"Zendesk",
            :match_details =>"unique header",
            :references => [],
            :match_type => :content_headers,
            :match_content =>  /^x-zendesk-origin-server:.*$/i,
            :examples => ["http://help.etsy.com:80"],
            :verify => ["ZXRzeSNJbnRyaWd1ZTo6RW50aXR5OjpVcmkjaHR0cDovL2hlbHAuZXRzeS5jb206ODA="],
            :paths => ["#{url}"]
          },
          { # TODO - this might catch valid (closed) helpdesk uris too.
            :type => "service",
            :vendor =>"Zendesk",
            :product =>"Zendesk",
            :match_details =>"zendesk access by IP / invalid hostname",
            :references => [],
            :hide => true,
            :match_type => :content_body,
            :match_content =>  /<title>Help Center Closed \| Zendesk/i,
            :examples => ["http://192.161.147.1:80"],
            :verify => ["a2VubmFzZWN1cml0eSNJbnRyaWd1ZTo6RW50aXR5OjpVcmkjaHR0cDovLzE5Mi4xNjEuMTQ3LjE6ODA="],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
