# coding: utf-8
Gem::Specification.new do |s|
  s.name        = 'intrigue-tasks'
  s.version     = '0.8.8'
  s.date        = '2021-09-02'
  s.summary     = "Intrigue Core Tasks"
  s.description = "Intrigue Core Task Library"
  s.authors     = ["jcran"]
  s.email       = 'jcran@intrigue.io'
  s.files       = Dir.glob("lib/tasks/*/*.rb").concat
                  Dir.glob("lib/tasks/*.rb").concat
                  Dir.glob("lib/system/*.rb").concat
                  Dir.glob("lib/checks/*.rb").concat
                  Dir.glob("lib/task_factory.rb").concat
                  Dir.glob("lib/issue_factory.rb").concat
                  Dir.glob("lib/issues/base.rb").concat ["lib/intrigue-tasks.rb"]
  s.require_paths = ['./lib']
  s.homepage    = 'http://github.com/intrigueio/intrigueio/intrigue-core'
  s.license     = 'BSD-3-Clause'
end
