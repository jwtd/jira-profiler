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
  # For each day/week/sprint
  #   For each issue type
  #   For each person
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
  # resolved or closed
  #   decomposed
  #   obe
  #   duplicate

  class Project < JiraApiBase
    include Logger

    attr_reader :id, :key, :name, :description, :sprint_schedule

    @@project_cache = {}


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

      @id   = options['id']
      @key  = options['key']
      @name = options['name']
      @description = options['description']
      #TODO: @versions = options['versions'].collect do {|v| v['name']}

      # Prepare references
      @sprints         = nil
      @sprint_schedule = nil
      @issues          = nil
      @activity        = ActiveSupport::OrderedHash.new()

    end


    # The manually created table of sprint names with corresponding start and end dates
    def sprints
      if @sprints.nil?

        # Create references
        @sprints         = ActiveSupport::OrderedHash.new()
        @sprint_schedule = ActiveSupport::OrderedHash.new()

        # Get the list of sprint names and IDs for this project from Jira
        rapid_view = self.class.get("/rest/greenhopper/1.0/sprintquery/#{id}")
        rapid_view['sprints'].each do |item|
          @sprints[item['name']] = JiraProfiler::Sprint.new(
            :project => self,
            :id      => item['id'],
            :name    => item['name']
          )
        end

        # Check to see if a valid project log file is provided
        sprint_schedule_filepath = "#{JiraProfiler.config.data_directory}/#{name.to_snake_case}_sprint_schedule.csv"
        unless File.exists?(sprint_schedule_filepath)
          logger.info "Did not find sprint schedule file at #{sprint_schedule_filepath}"
        else
          logger.info "Overriding Jira data with values found in sprint schedule file at #{sprint_schedule_filepath}"

          # If a project log file is found, correct Jira's data with its contents
          data = CSV.read(log_filepath, { encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all})
          data.each do |row|
            from_date = Date.strptime(row[:from], "%m/%d/%y")
            # Correct Jira's sprint data
            sprint = @sprints[row[:sprint].to_s]
            sprint.start_date = from_date,
            sprint.end_date   = Date.strptime(row[:to], "%m/%d/%y"),
            sprint.note       = row[:note]
          end

        end

        # Create a reference of the start dates for all sprints
        @sprints.each do |sprint|
          @sprint_schedule[sprint.start_date.as_sortable_date] = sprint
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
              # else
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


    # An Ordered Hash reflecting the day by day sprint calendar for the project, keyed by date in YYY.MM.DD format
    def calendar(from_date = nil, to_date = nil)
      if @calendar.nil?
        logger.debug "Building project calendar"

        # Establish the bounds of the calendar
        @calendar    = ActiveSupport::OrderedHash.new()
        from_date    = sprints.values.first.start_date if from_date.nil?
        to_date      = Date.today() if to_date.nil?
        sprint_label = nil

        # Add all days between start date and today
        (from_date..to_date).each_with_index do |cur_date, day_index|

          date_key       = cur_date.as_sortable_date
          sprint_label   = sprint_schedule.fetch(date_key, sprint_label)
          day_of_sprint  = cur_date.days_from(sprint.from_date).to_i
          week_of_sprint = day_of_sprint / 7
          week_index     = day_index / 7       # week_index is the number of weeks that have passed since the start of the calendar
          # weekday_index  = cur_date.wday
          # weekday        = cur_date.strftime('%A') # Sunday

          # Build up a reference table with date and sprint data
          @calendar[date_key] = {
            :date       => cur_date,
            :uweek      => cur_date.strftime('%U').to_i + 1,
            :day_index  => day_index + 1,
            :week_index => week_index,
            :day_of_sprint => day_of_sprint,
            :week_of_sprint => week_of_sprint,
            :sprint      => sprints[sprint_label],
            :issue_types => {}, # TODO: Add a key for each type initilized to {:created => 0}
            :assignees   => {},  # TODO: Add a key for each user initilized to {:created => 0}
          }
          # puts "#{date_key} : #{week_index} : #{day_index} : Sprint #{sprint.label} (#{days_in_sprint}): #{week_of_sprint} : #{day_of_sprint} : #{cur_date.weekend?} : #{weekday} (#{weekday_index})"

        end
      end
      @calendar
    end


    # An Ordered Hash reflecting the day by day project activity, keyed by date in YYY.MM.DD format
    def history
      if @history.nil?
        @history = calendar
        logger.info "Calculating stats for #{issues.count} issues"

        calendar.each_pair do |date_key, date_data|

          # Prepare to calculate the totals for sprints
          unless @sprints.has_key?(date_data[:sprint])
            @sprints[date_data[:sprint]] = {
              :assignees   => {},
              :issue_types => {},
              :calendar    => ActiveSupport::OrderedHash.new()
            }
          end

          # Get type data reference
          sprint_data   = @sprints[date_data[:sprint]]
          assignee_data = date_data[:assignees]
          type_data     = date_data[:issue_types]

          # Loop over each activity for the day and talley up event counts
          activity.fetch(date_key, [])
          activity.each do |change|

            # Prepare to save for assignees
            unless assignee_data.has_key?(change.assignee)
              assignee_data[change.assignee] = {}
              sprint_data[:assignees][change.assignee] = {}
            end

            # Make sure there is hash for this type
            unless type_data.has_key?(change.issue.type)
              type_data[change.issue.type] = {}
              sprint_data[:issue_types][change.issue.type] = {}
              assignee_data[change.assignee][change.issue.type] = {}
              sprint_data[:assignees][change.assignee][change.issue.type] = {}
            end

            # Make sure there is an array for the event type
            unless type_data[change.issue.type].has_key?(change.event)
              type_data[change.issue.type][change.event] = Set.new()
              sprint_data[:issue_types][change.issue.type][change.event] = Set.new()
              assignee_data[change.assignee][change.issue.type][change.event] = Set.new()
              sprint_data[:assignees][change.assignee][change.issue.type][change.event] = Set.new()
            end

            # Add the issue to the sets
            type_data[change.issue.type][change.event] << change.issue
            sprint_data[:issue_types][change.issue.type][change.event] << change.issue
            assignee_data[change.assignee][change.issue.type][change.event] << change.issue
            sprint_data[:assignees][change.assignee][change.issue.type][change.event] << change.issue

          end

        end

      end
      @history
    end


    def record_change(change)
      d = change.date.as_sortable_date
      unless @activity.has_key?(d)
        @activity[d] = [change]
      else
        @activity[d] << change
      end
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