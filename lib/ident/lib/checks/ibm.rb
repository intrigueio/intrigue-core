module Intrigue
module Ident
module Check
  class Ibm < Intrigue::Ident::Check::Base

    def generate_checks(url)
      [
        {
          :type => "application",
          :vendor => "IBM",
          :product =>"Datapower",
          :references => ["https://www.ibm.com/developerworks/community/blogs/HermannSW/entry/datapower_x_backside_transport_transfer_encoding_and_connection_header_fields9?lang=en"],
          :version => nil,
          :match_type => :content_headers,
          :match_content =>  /X-Backside-Transport:/i,
          :match_details =>"header thrown by ibm datapower (on error?)",
          :examples => ["https://css-ewebsvcs.freddiemac.com:443"],
          :paths => ["#{url}"]
        },
        {
          :type => "application",
          :vendor => "IBM",
          :product =>"IBM Security Access Manager for Web",
          :references => ["https://www.ibm.com/support/knowledgecenter/SSPREK_9.0.2.1/com.ibm.isam.doc/wrp_config/concept/con_sam_intro.html"],
          :version => nil,
          :match_type => :content_headers,
          :match_content =>  /www-authenticate: Basic realm=\"IBM Security Access Manager for Web\"/i,
          :match_details =>"IBM security access manager login prompt",
          :examples => ["https://161.107.22.69:443"],
          :paths => ["#{url}"]
        },
        {
          :type => "application",
          :vendor => "IBM",
          :product =>"Tivoli Access Manager for e-business",
          :references => ["https://www.ibm.com/support/knowledgecenter/en/SSPREK_6.1.0/com.ibm.itame.doc_6.1/am61_qsg_en.htm"],
          :version => nil,
          :match_type => :content_body,
          :match_content =>  /<title>Access Manager for e-Business Login/i,
          :match_details =>"Generic Ibm tivoli copyright",
          :examples => ["https://161.107.1.22:443"],
          :paths => ["#{url}"]
        },
        {
          :type => "application",
          :vendor => "IBM",
          :product =>"WebSEAL",
          :references => ["https://www.ibm.com/support/knowledgecenter/en/SSPREK_8.0.1.2/com.ibm.isamw.doc_8.0.1.2/wrp_config/task/tsk_submt_form_data_ws.html"],
          :version => nil,
          :match_type => :content_body,
          :match_content =>  /<form method=\"POST\" action=\"\/pkmslogin.form\">/i,
          :match_details =>"form action to submit to webseal (on ourselves)",
          :examples => ["https://pseuat.fmrei.com:443"],
          :paths => ["#{url}"]
        }

      ]
    end

  end
end
end
end
