# Base exception class
module JiraProfiler
  class JiraProfilerError < ::Exception; end
end

require "jira-profiler/core_extensions/string"
String.include CoreExtensions::String

require "jira-profiler/version"
require "jira-profiler/logger"
require "jira-profiler/configuration"
require "jira-profiler/team"
require "jira-profiler/project"