require 'pp'

module JiraProfiler

  # A command line interface to retrieve the data from Jira
  # Jira REST api https://docs.atlassian.com/jira/REST/latest/

  class Cli

    class << self

      include Logger

      attr_reader :args, :options, :team

      def run(task, args, options)
        logger.debug "Run #{JiraProfiler.config.app_name} #{JiraProfiler::VERSION::STRING} command #{task}"
        logger.debug "args: #{args.inspect}"
        logger.debug "options: #{options.inspect}"
        JiraProfiler.config.update(options.__hash__)
        logger.debug "Running with config #{JiraProfiler.config.inspect}"
        initialize_response_cache()
        self.send task, args, options
      end

      # Facilitate normalization of all versions of a team member's name to one value
      def standardize_name(name)
        @team.nil? ? name : @team.standardize_name(name)
      end


      private


      # Setup response cache in HTTParty
      def initialize_response_cache(params={})
        param = {
         :use_cache    => JiraProfiler.config.use_cache,
         :cache_domain => JiraProfiler.config.app_name,
         :cache_dir    => './http-response-cache',
         :timeout_length         => 10, # seconds
         :cache_stale_backup_time => 0  # minutes
        }.merge(params)

        logger.debug "HTTParty::HTTPCache params = #{param.inspect}"
        logger.info "HTTParty::HTTPCache = #{param[:use_cache]}"

        # Create a file system based cache
        @@cache = HTTParty::FileCache.new(param[:cache_domain], param[:cache_dir], 0)

        # Setup HTTParty::HTTPCache
        HTTParty::HTTPCache.cache = @@cache
        HTTParty::HTTPCache.perform_caching = param[:use_cache]
        HTTParty::HTTPCache.logger = JiraProfiler::Logger.logger(HTTParty::HTTPCache)
        HTTParty::HTTPCache.timeout_length = param[:timeout_length]
        HTTParty::HTTPCache.cache_stale_backup_time = param[:cache_stale_backup_time]
        HTTParty::HTTPCache.exception_callback = lambda { |exception, api_name, url|
          logger.error "#{api_name}::#{url} returned #{exception}"
        }
      end

      # Setup for all commands
      def profile(args, options)
        # Create team and get project data
        @team = Team.new("#{options.project} Team", options.team_data_file)
        p = Project.new(options.project)
        fi = p.issues.first
        puts "fi.statuses: #{fi.statuses}"
        puts "fi.accumulated_time_in_status: #{fi.accumulated_time_in_status()}"
        puts "fi.elapsed_time_in_status: #{fi.elapsed_time_in_status()}"

        # Loop over each issue in the project
        #s = p.sprints
        #pp c = p.contributors

      end

    end

  end

end