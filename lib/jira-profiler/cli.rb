require 'pp'

module JiraProfiler

  # A command line interface to retrieve the data from Jira
  # Jira REST api https://docs.atlassian.com/jira/REST/latest/

  #--------------------------------------------------------------
  #                 Main objectives of program                  #
  #--------------------------------------------------------------

  # Company & Developer vacation log from Google Calendar
  #    https://developers.google.com/google-apps/calendar/quickstart/ruby

  # Sprint calendar log
  # Sprint 26 was from 4/22/14 - 5/6/2014
  # '2014.04.02' => {date: d, sprint: "Sprint #{sprint_num}"}


  # Primary objects
  #  Projects -> Issues -> Tasks -> Transitions
  #  People -> Issues -> Tasks -> Transitions
  #  Sprints -> Issues -> People
  #  Issue types

  # For Project
  #   Sprints
  #   Epics
  #   Issues
  #   Developers
  #   Components

  # For Sprint
  #   Developer
  #    # of stories
  #    # of points
  #    # of days
  #    # of incomplete
  #   AVG Time spent in development
  #   AVG Time spent in review
  #   AVG Time spent in QA
  #   # of Scheduled
  #   # non-scheduled
  #   AVG Time spent on scheduled
  #   AVG Time spent in non-scheduled

  # For story
  #   Age in days
  #   Dev time in days
  #   Spanned across X sprints (incompleted = S-1)
  #   Time spent in development
  #   Time spent in review
  #   Time spent in QA
  #   Scheduled vs non-scheduled

  # Objectives
  # Report sprint profiles - For each sprint
  #   number of issues at start
  #   number of issues at end
  #   number of issues added
  #   number of issues completed vs not completed
  #   points added
  #   points completed vs not completed
  # Report elapsed time
  #   between issues status transitions
  #   for entire story
  #   for each point Size across team
  #   for each point Size by team member
  # Report ratio of
  #   type of issues (stories vs defects)
  #   epics
  #   tags
  # Average number of sprints per story completed in each sprint
  #  "customfield_10007"=>
  # ["com.atlassian.greenhopper.service.sprint.Sprint@1d249cb[id=162,rapidViewId=26,state=CLOSED,name=Sprint 55,startDate=2015-06-09T14:47:33.197-04:00,endDate=2015-06-22T14:47:00.000-04:00,completeDate=2015-06-23T13:23:46.910-04:00,sequence=162]",
  #  "com.atlassian.greenhopper.service.sprint.Sprint@aacc28[id=164,rapidViewId=33,state=ACTIVE,name=Sprint 56 - Dev Ops,startDate=2015-06-24T11:23:44.342-04:00,endDate=2015-07-06T11:23:00.000-04:00,completeDate=<null>,sequence=164]"],


  class Cli

    # Only look up Jira objects once
    @@user_cache    = nil
    @@project_cache = nil
    @@issue_cache   = nil

    class << self

      include Logger

      attr_reader :args, :options

      # Single entry point for all commands, that initilizes the CLI
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

      # The field reference for the system
      def self.available_users
        if @@user_cache.nil?
          @@user_cache = {}
          r = get(get("/rest/api/2/user/search?username=%"))
          r.each do |data|
            @@user_cache[data['displayName']] = JiraProfiler::User.new(data)
          end
        end
        @@user_cache
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
        p = Project.find_by_name(options.project)
        fi = p.issues.first
        puts "fi.statuses: #{fi.statuses}"
        puts "fi.accumulated_time_in_status: #{fi.accumulated_time_in_status('Open')}"
        puts "fi.elapsed_time_in_status: #{fi.elapsed_time_in_status('Open')}"

        # Loop over each issue in the project
        s = p.sprints
        #pp c = p.contributors

        # history = OrderedHash.new()
        # For each date
        # r = Record.new()
        # d    = Date
        # S    = Project.active_sprint_on(date)
        # Sw   = Project.week_of_sprint_on(date)
        # Sd   = Project.day_of_sprint_on(date)
        #
        # history[YYYY.MM.DD] << Record.new(r)
        #
        # project.each do |p|
        #   p.issues.each do |i|
        #     record_issue(i)
        #     issue.subtasks.each do |s|
        #       record_issue(i,s)
        #     end
        #   end
        # end
        #
        # record_issue(issue, subtask = nil)
        # issue.transitions.each do |t|
        #   record_transition(t)
        # end
        #
        # record_transition(t)

      end

    end

  end

end