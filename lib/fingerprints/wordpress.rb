module Intrigue
  module Fingerprint
    class Wordpress < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        [
          {
            :uri => "#{uri}/wp-json",
            :checklist => [
              {
                :name => "Wordpress",
                :description => "Wordpress WP-JSON endpoint",
                :version => nil,
                :type => :content_body,
                :content => /gmt_offset/
              }
            ]
        },
        {
          :uri => "#{uri}/wp-includes/js/tinymce/tiny_mce.js",
          :checklist => [
            {
              :name => "Wordpress",
              :description => "Wordpress TinyMCE Editor",
              :references => ["https://dcid.me/texts/fingerprinting-web-apps.html"],
              :version => "2.0",
              :type => :checksum_body,
              :checksum => "a306a72ce0f250e5f67132dc6bcb2ccb"
            },
            {
              :name => "Wordpress",
              :description => "Wordpress TinyMCE Editor",
              :references => ["https://dcid.me/texts/fingerprinting-web-apps.html"],
              :version => "2.1",
              :type => :checksum_body,
              :checksum => "4f04728cb4631a553c4266c14b9846aa"
            },
            {
              :name => "Wordpress",
              :description => "Wordpress TinyMCE Editor",
              :references => ["https://dcid.me/texts/fingerprinting-web-apps.html"],
              :version => "2.2",
              :type => :checksum_body,
              :checksum => "25e1e78d5b0c221e98e14c6e8c62084f"
            },
            {
              :name => "Wordpress",
              :description => "Wordpress TinyMCE Editor",
              :references => ["https://dcid.me/texts/fingerprinting-web-apps.html"],
              :version => "2.3",
              :type => :checksum_body,
              :checksum => "83c83d0f0a71bd57c320d93e59991c53"
            },
            {
              :name => "Wordpress",
              :description => "Wordpress TinyMCE Editor",
              :references => ["https://dcid.me/texts/fingerprinting-web-apps.html"],
              :version => "2.5",
              :type => :checksum_body,
              :checksum => "7293453cf0ff5a9a4cfe8cebd5b5a71a"
            },
            {
              :name => "Wordpress",
              :description => "Wordpress TinyMCE Editor",
              :references => ["https://dcid.me/texts/fingerprinting-web-apps.html"],
              :version => "2.6",
              :type => :checksum_body,
              :checksum => "61740709537bd19fb6e03b7e11eb8812"
            },
            {
              :name => "Wordpress",
              :description => "Wordpress TinyMCE Editor",
              :references => ["https://dcid.me/texts/fingerprinting-web-apps.html"],
              :version => "2.7",
              :type => :checksum_body,
              :checksum => "e6bbc53a727f3af003af272fd229b0b2"
            },
            {
              :name => "Wordpress",
              :description => "Wordpress TinyMCE Editor",
              :references => ["https://dcid.me/texts/fingerprinting-web-apps.html"],
              :version => "2.7.1",
              :type =>:checksum_body,
              :checksum => "e6bbc53a727f3af003af272fd229b0b2"
            },
            {
              :name => "Wordpress",
              :description => "Wordpress TinyMCE Editor",
              :references => ["https://dcid.me/texts/fingerprinting-web-apps.html"],
              :version => "2.9.1",
              :type => :checksum_body,
              :checksum => "128e75ed19d49a94a771586bf83265ec"
            }
          ]
        }]
      end


=begin
all_checks = [{
  :uri => "#{uri}",
  :checklist => [
  {
    :name => "Yoast Wordpress SEO Plugin", # won't be used if we have
    :description => "Yoast Wordpress SEO Plugin",
    :type => "content",
    :content => /<!-- \/ Yoast WordPress SEO plugin. -->/,
    :test_site => "https://ip-50-62-231-56.ip.secureserver.net",
    :dynamic_name => lambda{|x| x.scan(/the Yoast WordPress SEO plugin v.* - h/)[0].gsub("the ","").gsub(" - h","") }
  }
]},
=end


    end
  end
end
