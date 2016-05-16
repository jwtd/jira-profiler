require 'httparty'

module JiraProfiler
  class JiraApiBase
    include HTTParty
    base_uri 'virtru.atlassian.net'
    basic_auth ENV.fetch('JIRA_UN'), ENV.fetch('JIRA_PW')
  end
end