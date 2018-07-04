# coding: utf-8
require './ident'

Gem::Specification.new do |spec|
  spec.name          = "intrigue-ident"
  spec.version       = Intrigue::Ident::VERSION
  spec.authors       = ["jcran"]
  spec.email         = ["jcran@intrigue.io"]

  spec.summary       = %q{Fingerprinter for Intrigue Data}
  spec.description   = %q{Fingerprinter for Intrigue Data}
  spec.homepage      = "https://intrigue.io"
  spec.license       = "BSD"
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
