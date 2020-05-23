# coding: utf-8
Gem::Specification.new do |s|

  s.name        = 'intrigue-tasks'
  s.version     = '0.08'
  s.date        = '2020-05-22'
  s.summary     = "Intrigue Core Tasks"
  s.description = "Intrigue Core Task Library"
  s.authors     = ["jcran"]
  s.email       = 'jcran@intrigue.io'
  s.files       = Dir.glob("tasks/*/*.rb").concat Dir.glob("tasks/*.rb").concat ["./intrigue-tasks.rb"]
  s.require_paths = ['.']
  s.homepage    = 'http://github.com/intrigueio/intrigueio/intrigue-core'
  s.license     = 'BSD-3-Clause'
 
end
