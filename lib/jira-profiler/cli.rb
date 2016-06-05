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

      def run(task, args, options)
        logger.debug "Run #{JiraProfiler.config.app_name} #{JiraProfiler::VERSION::STRING} command #{task}"
        logger.debug "args: #{args.inspect}"
        logger.debug "options: #{options.inspect}"
        JiraProfiler.config.update(options.__hash__)
        logger.debug "Running with config #{JiraProfiler.config.inspect}"
        initialize_response_cache(options)
        self.send task, args, options
      end


      private


      # Setup response cache in HTTParty
      def initialize_response_cache(params)
        param = {
         :use_cache    => JiraProfiler.config.use_cache,
         :cache_domain => JiraProfiler.config.app_name,
         :cache_dir    => './http-response-cache',
         :timeout_length         => 10, # seconds
         :cache_stale_backup_time => 0  # minutes
        }.merge(params.__hash__)
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
        puts "options.project: #{options.project}"
        puts "options.team_data_file: #{options.team_data_file}"



        #t = Team.new("#{options.team_data_file} Team")
        #p = Project.new(options.project)
        #s = p.sprints
        #i = p.issues
        #pp c = p.contributors

      end

    end

  end

end