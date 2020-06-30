# coding: utf-8
Gem::Specification.new do |s|

  s.name        = 'intrigue-tasks'
  s.version     = '0.1.2'
  s.date        = '2020-06-29'
  s.summary     = "Intrigue Core Tasks"
  s.description = "Intrigue Core Task Library"
  s.authors     = ["jcran"]
  s.email       = 'jcran@intrigue.io'
  s.files       = Dir.glob("lib/tasks/*/*.rb").concat Dir.glob("lib/tasks/*.rb").concat Dir.glob("lib/systmem/*.rb").concat ["lib/intrigue-tasks.rb"]
  s.require_paths = ['./lib']
  s.homepage    = 'http://github.com/intrigueio/intrigueio/intrigue-core'
  s.license     = 'BSD-3-Clause'
 
end
