require 'active_support/all'
require 'csv'
require 'set'
require 'pp'

module JiraProfiler

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

  class Project < JiraApiBase
    include Logger

    attr_reader :id, :key, :name, :description, :contributors

    @@project_cache = {}

    ProjectLogEntry = Struct.new(:label, :from_date, :to_date, :note)


    # Class methods ------------------


    class << self

      # Look up project by project id
      def find_by_id(id)
        find_by('id', id)
      end

      # Look up project by project key
      def find_by_key(key)
        find_by('key', key)
      end

      # Look up project by project name
      def find_by_name(name)
        find_by('name', name)
      end

      # Look up project by project id
      def find_by(attribute, value)
        if @@project_cache.has_key?(value)
          project = @@project_cache[value]
        else
          project_id = lookup_id_for(attribute, value)
          project = get_project(project_id)
        end
        return project
      end

      # Loop over all of the projects to find the id of the project whose attribute matches the value provided
      def lookup_id_for(attribute, value)
        return value if attribute == 'id'
        project_list = get("/rest/api/2/project")
        project_list.each do |project|
          return project['id'] if project[attribute] == value
        end
      end

      # Cache project instances to avoid rebuilding multiple times
      def get_project(id)
        project = new(get("/rest/api/2/project/#{id}"))
        @@project_cache[project.name] = project
        @@project_cache[project.id]   = project
        @@project_cache[project.key]  = project
        return project
      end

    end


    # Instance methods ------------------


    def initialize(options)
      # Get issues metadata
      @id   = options['id']
      @key  = options['key']
      @name = options['name']
      @description = options['description']
      #TODO: @versions = options['versions'].collect do {|v| v['name']}
      # Prepare references
      @issue_fields = nil
      @sprints = nil
    end


    # The manually created table of sprint names with corresponding start and end dates
    def schedule
      if @schedule.nil?
        # Validate presence of project_log
        log_filepath = './data/web_stack_log.csv'
        raise "Project schedule could not be found at #{log_filepath}" unless File.exists?(log_filepath)
        # Import the sprint log
        @schedule = ActiveSupport::OrderedHash.new()
        data = CSV.read(log_filepath, { encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all})
        data.each do |row|
          from_date = Date.strptime(row[:from], "%m/%d/%y")
          @schedule[from_date.strftime('%Y.%m.%d')] = ProjectLogEntry.new(
            row[:sprint].to_s,
            from_date,
            Date.strptime(row[:to], "%m/%d/%y"),
            row[:note]
          )
        end
      end
      @schedule
    end


    # An Ordered Hash reflecting the day by day sprint calendar for the project, keyed by date in YYY.MM.DD format
    def calendar(from_date = nil, to_date = nil)
      if @calendar.nil?

        @calendar  = ActiveSupport::OrderedHash.new()
        from_date = schedule.values.first.from_date if from_date.nil?
        to_date   = Date.today() if to_date.nil?
        sprint    = nil

        # Add all days between start date and today
        (from_date..to_date).each_with_index do |cur_date, day_index|

          date_key       = cur_date.strftime('%Y.%m.%d')
          sprint         = schedule.fetch(date_key, sprint)
          days_in_sprint = sprint.to_date.days_from(sprint.from_date).to_i
          day_of_sprint  = cur_date.days_from(sprint.from_date).to_i
          week_of_sprint = day_of_sprint / 7
          week_index     = day_index / 7
          weekday_index  = cur_date.wday
          weekday        = cur_date.strftime('%A') # Sunday

          @calendar[date_key] = {
            :date       => cur_date,
            :uweek      => cur_date.strftime('%U').to_i + 1,
            :day_index  => day_index + 1,
            :week_index => week_index,
            :day_of_sprint => day_of_sprint,
            :week_of_sprint => week_of_sprint,
            :sprint     => sprint
          }
          puts "#{date_key} : #{week_index} : #{day_index} : Sprint #{sprint.label} (#{days_in_sprint}): #{week_of_sprint} : #{day_of_sprint} : #{cur_date.weekend?} : #{weekday} (#{weekday_index})"
        end
      end
      @calendar
    end


    # An Ordered Hash reflecting the day by day project activity, keyed by date in YYY.MM.DD format
    def history
      if @history.nil?
        issues.each do |issue|
          record_issue(issue)
          issue.subtasks.each do |subtask|
            record_issue(issue, subtask)
          end
        end
      end
      @history
    end


    def record_issue(issue, subtask = nil)
      issue.transitions.each do |transition|
        record_transition(transition)
      end
    end


    def record_transition(transition)

      date_key = transition.start_date.strftime('%Y.%m.%d')

      # calendar[date_key][]={}
      #
      # issue
      #   type
      #   assignee
      # transition
      #   created
      #   decomposed
      #   sized
      #   resized
      #   added
      #   removed
      #   assigned
      #   started
      #   ready
      #   reviewed
      #   closed
      #   reopend


    end

    # The list of sprints which are recorded in Jira (note, these dates may not be reliable if Jira isn't maintained religously)
    def sprints
      if @sprint.nil?
        @sprints = ActiveSupport::OrderedHash.new()
        rapid_view = self.class.get("/rest/greenhopper/1.0/sprintquery/#{id}")
        rapid_view['sprints'].each do |item|
          sprint = Sprint.new(id, item['id'])
          @sprints[sprint.name] = sprint
        end
      end
      @sprints
    end


    # Returns all issues in project
    def issues
      if @issues.nil?
        @issues = {}
        max_result = 3
        jql = "/rest/api/2/search?jql=project=\"#{name}\" AND issuetype NOT IN (Epic, Sub-task)&expand=changelog&maxResults=#{max_result}"
        #r = nil
        #without_cache{ r = self.class.get("#{jql}&startAt=0") }
        r = self.class.get("#{jql}&startAt=0")
        pages = (r['total'] / max_result)
        (0..pages).each do |current_page|
          begin
            # If you can get the latest version of the last page, do so, otherwise load the cached version
            query = "#{jql}&startAt=#{(current_page * max_result)}"
            if current_page == pages
              #without_cache{ r = self.class.get(query) }
              r = self.class.get(query)
            else
              r = self.class.get(query)
            end
            r['issues'].each do |issue|
              # Cast raw response to Issue(), passing project reference into constructor
              issue['project'] = self
              @issues[issue['key']] = Issue.new(issue)
            end
          # rescue => exception
          #   puts "#{exception.message} (#{exception.class})"
          #   pp exception.backtrace
          end
        end
      end
      @issues
    end


    # The list of users who worked on this project
    def contributors
      if @contributors.nil?
        @contributors = Set.new()
        issues.each do |issue|
          @contributors.merge(issue.contributors)
        end
      end
      @contributors
    end

  end

end