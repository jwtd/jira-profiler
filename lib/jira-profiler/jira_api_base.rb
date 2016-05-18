require 'httparty'
require 'httparty-filecache'

module JiraProfiler

  class JiraApiBase

    include HTTParty
    base_uri 'virtru.atlassian.net'
    basic_auth ENV.fetch(JiraProfiler.configuration.jira_un_env_key),
               ENV.fetch(JiraProfiler.configuration.jira_pw_env_key)
    caches_api_responses :host=> 'virtru.atlassian.net', :key_name => "desk", :expire_in => 0

    # Setup response cache in HTTParty
    def initialize_response_cache
      # TODO: Set to domain of API being called
      cache_domain = JiraProfiler.configuration.app_name
      @@cache = HTTParty::FileCache.new(cache_domain, "./http-response-cache", 0)
      # Setup HTTParty
      HTTParty::HTTPCache.cache = @@cache
      HTTParty::HTTPCache.perform_caching = true
      HTTParty::HTTPCache.logger = JiraProfiler.logger(HTTParty::HTTPCache)
      HTTParty::HTTPCache.timeout_length = 0 # seconds
      HTTParty::HTTPCache.cache_stale_backup_time = 0 # minutes
      HTTParty::HTTPCache.exception_callback = lambda { |exception, api_name, url|
        logger.error "#{api_name}::#{url} returned #{exception}"
      }
    end

  end

end