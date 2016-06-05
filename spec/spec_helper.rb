$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'coveralls'
Coveralls.wear!

require 'pry'
require 'jira-profiler'

require 'rspec_command'

# https://github.com/coderanger/rspec-command
RSpec.configure do |config|
  config.include RSpecCommand
end