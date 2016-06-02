require 'pp'

module JiraProfiler

  # A command line interface to retrieve the data from Jira

  # Facilitate normalization of all versions of a team member's name to one value
  def self.standardize_name(name)
    return @team_data['aliases'].fetch(name, name)
  end

  class Cli

    class << self

      include Logger

      attr_reader :args, :options

      def profile(args, options)
        logger.debug "Start profile - args: #{args.inspect}, options: #{options.inspect}"
        @args    = args
        @options = options
        initialize_cli
        profile_project
      end


      private


      # Setup for all commands
      def initialize_cli
        #@config = JiraProfiler.configure_from_yaml_file(options[:config]) unless options[:config].nil?
        logger.info "Initializing Jira Profiler #{JiraProfiler::VERSION::STRING}"
        initialize_response_cache
        validate_required_global_settings
        logger.debug JiraProfiler.configuration.inspect
        load_team_data(JiraProfiler.configuration.team_data_file)
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
        logger.info "HTTParty::HTTPCache.perform_caching = #{JiraProfiler.configuration.use_cache}"
        # TODO: Set to domain of API being called
        cache_domain = JiraProfiler.configuration.app_name
        @@cache = HTTParty::FileCache.new(cache_domain, "./http-response-cache", 0)
        HTTParty::HTTPCache.cache = @@cache
        HTTParty::HTTPCache.perform_caching = JiraProfiler.configuration.use_cache
        HTTParty::HTTPCache.logger = JiraProfiler::Logger.logger(HTTParty::HTTPCache)
        HTTParty::HTTPCache.timeout_length = 10 # seconds
        HTTParty::HTTPCache.cache_stale_backup_time = 0 # minutes
        HTTParty::HTTPCache.exception_callback = lambda { |exception, api_name, url|
          logger.error "#{api_name}::#{url} returned #{exception}"
        }
      end

      # Reference for team data
      def load_team_data(team_filepath)
        logger.debug team_filepath
        if File.exists?(team_filepath)
          @team_data = JSON.parse(File.read(team_filepath))
        else
          logger.error "Could not find team data file at #{team_filepath}"
        end
      end

      # Setup for all commands
      def profile_project
        puts "options.project: #{options.project}"
        t = Team.new("#{options.project} Team")
        p = Project.new(options.project)
        #s = p.sprints
        #i = p.issues
        pp c = p.contributors

      end

    end

  end

end