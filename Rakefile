require "bundler/gem_tasks"
require 'rspec/core/rake_task'
begin
  require 'rspec/scaffold'
rescue LoadError
  nil
end

RSpec::Core::RakeTask.new(:spec)
task default: :spec
