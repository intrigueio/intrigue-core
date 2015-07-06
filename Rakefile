require 'rspec/core'
require 'rspec/core/rake_task'

task :default => :spec

desc "Run Specs"
begin
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # No rspec available
end

desc "Run Integration Specs"
begin
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.rspec_opts = "--pattern spec/integration/*_spec.rb"
  end
rescue LoadError
  # No rspec available
end
