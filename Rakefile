require "bundler/gem_tasks"
require "rspec/core/rake_task"

# Run with `rake spec` or `rake test`
RSpec::Core::RakeTask.new(:spec)
task :test do
  Rake::Task["spec"].invoke
end

task :default => :spec

