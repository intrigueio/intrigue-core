# coding: utf-8
Gem::Specification.new do |s|
  s.name        = 'intrigue_api_client'
  s.version     = '1.6.0'
  s.date        = '2017-07-17'
  s.summary     = "API client for intrigue-core"
  s.description = "API client for intrigue-core"
  s.authors     = ["jcran"]
  s.email       = 'jcran@intrigue.io'
  s.files       = ["lib/intrigue_api_client.rb"]
  s.homepage    = 'http://rubygems.org/gems/intrigue_api_client'
  s.license     = 'BSD-3-Clause'
  s.add_dependency 'rest-client', '~> 2.0'
  s.add_dependency 'json', '~> 1.8'
end
