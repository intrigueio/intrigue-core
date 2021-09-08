# coding: utf-8
Gem::Specification.new do |s|
  s.name        = 'intrigue-workflows'
  s.version     = '0.8.8'
  s.date        = '2021-09-02'
  s.summary     = "Intrigue Core Workflows"
  s.description = "Intrigue Core Workflow Library"
  s.authors     = ["jcran"]
  s.email       = 'jcran@intrigue.io'
  s.files       = Dir.glob("lib/intrigue-workflows.rb").concat Dir.glob("lib/workflows/*.yml")
  s.require_paths = ['./lib']
  s.homepage    = 'http://github.com/intrigueio/intrigueio/intrigue-core'
  s.license     = 'BSD-3-Clause'
end
