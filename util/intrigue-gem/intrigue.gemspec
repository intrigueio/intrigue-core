Gem::Specification.new do |s|
  s.name        = 'intrigue'
  s.version     = '0.0.9'
  s.date        = '2015-07-19'
  s.summary     = "API client for intrigue-core"
  s.description = "API client for intrigue-core"
  s.authors     = ["jcran"]
  s.email       = 'jcran@intrigue.io'
  s.files       = ["lib/intrigue.rb"]
  s.homepage    = 'http://rubygems.org/gems/intrigue'
  s.license     = 'BSD'
  s.add_dependency 'rest-client', '~> 1.8'
  s.add_dependency 'json', '~> 1.8'
end
