# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jira-profiler/version'

Gem::Specification.new do |spec|
  spec.name          = 'jira-profiler'
  spec.version       = JiraProfiler::VERSION::STRING
  spec.authors       = ['Jordan Duggan']
  spec.email         = ['Jordan.Duggan@Gmail.com']

  spec.summary       = %q{Command line tool to analyze project, team, and user activity in Jira.}
  spec.description   = %q{Command line tool to analyze project, team, and user activity in Jira.}
  spec.homepage      = 'https://github.com/jwtd/jira-profiler'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Dev dependencies
  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 11.0'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'rspec-nc'
  spec.add_development_dependency 'rspec-command'
  spec.add_development_dependency 'factory_girl'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-bundler'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-remote'
  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'codeclimate-test-reporter'

  # Runtime dependencies
  spec.add_dependency 'activesupport'
  spec.add_dependency 'logging', '~> 2.1.0'
  spec.add_dependency 'httparty'
  spec.add_dependency 'httparty-filecache'
  spec.add_dependency 'commander'
  spec.add_dependency 'time_difference', '~> 0.4.2'

end
