require 'active_support/all'
require 'pp'

module JiraProfiler

  # Developer
  #  # of stories
  #  # of points
  #  # of days
  #  # of incomplete
  # AVG Time spent in development
  # AVG Time spent in review
  # AVG Time spent in QA
  # # of Scheduled
  # # non-scheduled
  # AVG Time spent on scheduled
  # AVG Time spent in non-scheduled

  # Get all users
  # https://virtru.atlassian.net/rest/api/2/user/search?username=%
  # {
  #     "self": "https://virtru.atlassian.net/rest/api/2/user?username=arichmond",
  #     "key": "arichmond",
  #     "name": "arichmond",
  #     "emailAddress": "arichmond@virtru.com",
  #     "avatarUrls": {
  #         "16x16": "https://virtru.atlassian.net/secure/useravatar?size=xsmall&avatarId=10122",
  #         "24x24": "https://virtru.atlassian.net/secure/useravatar?size=small&avatarId=10122",
  #         "32x32": "https://virtru.atlassian.net/secure/useravatar?size=medium&avatarId=10122",
  #         "48x48": "https://virtru.atlassian.net/secure/useravatar?avatarId=10122"
  #     },
  #     "displayName": "Allyson Richmond",
  #     "active": true,
  #     "timeZone": "America/Denver",
  #     "locale": "en_US"
  # },

  class User < JiraApiBase
    include Logger

    attr_reader :key, :name, :username, :active, :email
    attr :projects, :sprints, :issues, :activity

    # Class methods ------------------


    class << self

      # Look up project by project name
      def find_by_username(username)
        user = Cli.available_users.fetch(username, nil)
        user = new(get("/rest/api/2/user/search?username=#{username}")) if user.nil?
        user
      end

    end


    # Instance methods ------------------


    def initialize(options)
      @key = options['key']
      @username = options['name']
      @name = options['displayName']
      @active = options['active']
      @email = options['emailAddress']

      @activity    = {}         # Calendar history
      @projects    = Set.new()
      @sprints     = Set.new()
      @issues      = Set.new()
    end

    def record_change(change)
      @projects << change.issue.project
      @issues   << change.issue
      d = change.date.as_sortable_date
      unless @activity.has_key?(d)
        @activity[d] = [change]
      else
        @activity[d] << change
      end
    end

  end

end