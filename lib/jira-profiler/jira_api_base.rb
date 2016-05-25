require 'httparty'
require 'httparty-filecache'

module JiraProfiler

  class JiraApiBase

    include HTTParty
    base_uri 'https://virtru.atlassian.net'
    basic_auth ENV.fetch(JiraProfiler.configuration.jira_un_env_key),
               ENV.fetch(JiraProfiler.configuration.jira_pw_env_key)
    caches_api_responses :key_name => "desk", :expire_in => 0

  end

end