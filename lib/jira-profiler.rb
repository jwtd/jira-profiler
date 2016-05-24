# Base exception class
module JiraProfiler
  class JiraProfilerError < ::Exception; end
end

require "jira-profiler/core_extensions/object"
Object.include CoreExtensions::Object

require "jira-profiler/core_extensions/string"
String.include CoreExtensions::String

require "jira-profiler/version"
require "jira-profiler/configuration"
require "jira-profiler/logger"
require "jira-profiler/cli"
require "jira-profiler/jira_api_base"
require "jira-profiler/person"
require "jira-profiler/team"
require "jira-profiler/project"
require "jira-profiler/sprint"
require "jira-profiler/issue"
require "jira-profiler/transition"
