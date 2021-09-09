# coding: utf-8
Gem::Specification.new do |s|
  s.name        = 'intrigue-issues'
  s.version     = '0.8.9'
  s.date        = '2021-09-02'
  s.summary     = "Intrigue Core Issues"
  s.description = "Intrigue Core Issues"
  s.authors     = ["jcran"]
  s.email       = 'jcran@intrigue.io'
  s.files       = Dir.glob("lib/system/*.rb").concat
                  Dir.glob("lib/issues*.rb").concat
                  Dir.glob("lib/checks/*.rb").concat
                  Dir.glob("lib/tasks/*/*.rb").concat
                  Dir.glob("lib/tasks/base.rb").concat
                  Dir.glob("lib/issues/base.rb").concat
                  Dir.glob("lib/task_factory.rb").concat
                  Dir.glob("lib/issue_factory.rb").concat ["lib/intrigue-issues.rb"]
  s.require_paths = ['./lib']
  s.homepage    = 'http://github.com/intrigueio/intrigueio/intrigue-core'
  s.license     = 'BSD-3-Clause'
end
