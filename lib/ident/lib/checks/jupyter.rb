module Intrigue
module Ident
module Check
  class Jupyter < Intrigue::Ident::Check::Base

    def generate_checks(url)
      [
        {
          :type => "application",
          :vendor => "Jupyter",
          :tags => [],
          :product =>"Notebook",
          :match_details =>"matched jupyterhub header",
          :match_type => :content_headers,
          :version => nil,
          :dynamic_version => lambda { |x| _first_header_capture(x,/^x-jupyterhub-version: (.*)$/) },
          :match_content =>  /x-jupyterhub-version:/i,
          :examples => ["https://18.18.154.11:443"],
          :paths => ["#{url}"]
        }
      ]
    end
  end
end
end
end
