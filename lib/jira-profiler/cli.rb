require 'thor'

module JiraProfiler

  # A command line interface to retrieve the data from Jira

  class Cli < Thor

    include Logger
    class_option :verbose, :type => :boolean, :aliases => :v, :default =>false
    class_option :project, :required => true

    desc '`profile`', 'Profiles specified Jira project.'
    def profile()
      initialize_cli
      profile_project(options)
    end


    private


    # Setup for all commands
    def initialize_cli
      @config = JiraProfiler.configure_from_yaml_file(options[:config]) unless options[:config].nil?
      initialize_response_cache
      validate_required_global_settings
    end

    def validate_required_global_settings
      if ENV[JiraProfiler.configuration.jira_un_env_key] and ENV[JiraProfiler.configuration.jira_pw_env_key]
        logger.debug('Found jira username and password')
      else
        logger.error %q(The Jira username and/or password are not set as environment variables. Assign valid values to the environment variables designated by the jira_un_env_key and jira_pw_env_key config options.)
        exit
      end
    end

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


    def profile_project(options)

    end

  end

end