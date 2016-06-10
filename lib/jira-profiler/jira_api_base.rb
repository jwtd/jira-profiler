require 'httparty'
require 'httparty-filecache'

module JiraProfiler

  class JiraApiBase

    include HTTParty
    base_uri 'https://virtru.atlassian.net'
    basic_auth ENV.fetch(JiraProfiler.configuration.jira_un_env_key),
               ENV.fetch(JiraProfiler.configuration.jira_pw_env_key)
    caches_api_responses :key_name => "desk", :expire_in => 0

    def without_cache(&block)
      logger.debug "Without cache"
      #HTTParty::HTTPCache.perform_caching = false
      yield
      #HTTParty::HTTPCache.perform_caching = true
      logger.debug "Resume with cache"
    end

  end

end