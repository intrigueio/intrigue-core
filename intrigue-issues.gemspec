# coding: utf-8
Gem::Specification.new do |s|
  s.name        = 'intrigue-issues'
  s.version     = '0.1.0'
  s.date        = '2020-06-15'
  s.summary     = "Intrigue Core Issues"
  s.description = "Intrigue Core Issues"
  s.authors     = ["jcran"]
  s.email       = 'jcran@intrigue.io'
  s.files       = Dir.glob("lib/issues*.rb").concat ["lib/intrigue-issues.rb"]
  s.require_paths = ['./lib']
  s.homepage    = 'http://github.com/intrigueio/intrigueio/intrigue-core'
  s.license     = 'BSD-3-Clause'
end
