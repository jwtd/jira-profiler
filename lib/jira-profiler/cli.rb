require 'thor'

module JiraProfiler

  # A command line interface to retrieve the data from Jira

  class Cli < Thor

    include Logger

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