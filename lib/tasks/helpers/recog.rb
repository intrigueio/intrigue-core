require 'recog'
require 'ostruct'


module Intrigue
module Task
module Recog

  def product_match_http_server_banner(banner)
    options = OpenStruct.new(color: false, detail: true, fail_fast: false, multi_match: true)
    ndb = Recog::DB.new("http_servers.xml");nil
    options.fingerprints = ndb.fingerprints;nil
    matcher = Recog::MatcherFactory.build(options);nil
    matcher.match_banner(banner)
  end

  def product_match_http_cookies(string)
    options = OpenStruct.new(color: false, detail: true, fail_fast: false, multi_match: true)
    ndb = Recog::DB.new("http_cookies.xml");nil
    options.fingerprints = ndb.fingerprints;nil
    matcher = Recog::MatcherFactory.build(options);nil
    matcher.match_banner(string)
  end


end
end
end
