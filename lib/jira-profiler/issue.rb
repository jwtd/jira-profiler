require 'set'
require 'pp'

module JiraProfiler

  class Issue < JiraApiBase
    include Logger

    attr_reader :project, :id, :key, :type, :status, :statuses, :status_history, :status_cat,
                :created_at, :dev_started_at, :completed_at,
                :reporter, :creator, :assignee,
                :summary, :description,
                :epic, :epic_issue,
                :sprints, :components, :labels,
                :changes, :contributors

    StatusIteration = Struct.new(:start_date, :end_date, :elapsed_time, :assignee, :sprint)

    # Look up project by project name
    def self.find_by(issue_id_or_label)
      self.new(get("/rest/api/2/issue/#{issue_id_or_label}?expand=changelog"))
    end

    # Given ID, Label, or json object
    def initialize(options)

      # If an id was provided, look it up, otherwise assume the option block is JSON returned from a JQL query
      if options.has_key?(:project)
        @project = options['project'] if options.has_key?(:project)
      else
        @project = JiraProfiler::Project.find_by(:project_name => options['fields']['project']['name'])
      end

      # Get issues metadata
      f            = options['fields']
      @id          = options['id']
      @key         = options['key']
      @type        = f['issuetype']['name']
      @reporter    = f['reporter']['displayName']
      @creator     = f['creator']['displayName']
      @assignee    = f['assignee']['displayName'] unless f['assignee'].nil? # John Doe
      @status      = f['status']['name']
      @status_cat  = f['status']['statusCategory']['name']
      @summary     = f['summary']
      @description = f['description']
      @epic        = f['epicField']['text'] if f['epicField']
      @epic_issue  = f['epic'] if f['epic']

      # Associations
      @comments     = f['comment']['comments'] if f['comment']
      @subtasks     = nil
      @sprints      = Set.new()
      @contributors = Set.new()

      # History & Stats
      @created_at  = DateTime.parse(f['created'])
      @statuses       = Set.new()
      @status_history = {}
      @changes      = []
      @cur_sprint   = nil
      @cur_assignee = nil
      @cur_status   = nil



      # Lookup and associate the value of each field with the name in the reference
      fields[:keys].each do |field_key, field_name|
        fields[:names][field_name] = f[field_key]
      end

      # Step through the issue's history and record transitions
      record_change(@created_at, 'status', '', 'Open')

      # Analyze the history
      log = jira_issue['changelog']['histories'].each do |h|
        date = DateTime.parse(h['created'])
        h['items'].each do |event|
          field = event['field']
          from  = event['fromString']
          to    = event['toString']
          record_change(date, field, from, to)
        end
      end

    end


    def [](name_or_key)
      fields[:names][name_or_key] if fields[:names].has_key?(name_or_key)
      fields[:keys][name_or_key] if fields[:keys].has_key?(name_or_key)
    end

    def fields
      @fields[type]
    end


    # Returns all subtasks beloning to a project
    def subtasks
      @subtasks unless @subtasks.nil?
      @subtasks = {}
      jql = "/rest/api/2/search?jql=parent=\"#{@key}\"&expand=changelog&maxResults=200"
      r = self.class.get(jql)
      r['issues'].each do |issue|
        # Cast raw response to Issue()
        @subtasks[issue['key']] = Issue.new(issue)
      end
      @subtasks
    end

    # How much time was spent in each of the statuses
    def accumulated_hours_in_status(status, assignee = :all)
      status_history[status].inject(0) do |sum, i|
        sum + i.elapsed_time if assignee == :all or assignee == i.assignee
      end
    end

    # How much time passed between the first time a status was set and the last time
    def elapsed_hours_in_status(status)
      status_history[status].first.start_date.hours_from(status_history[status].last.end_date)
    end


    private


    # Recrods relevant changes, but not all items in history
    def record_change(date, field, from, to)

      # Track changes in issue status
      if field == 'status'
        # Set the ending date of the last status
        if status_history.has_key?(from)
          status_history[from].last[:end_date] = date
          status_history[from].last[:elapsed_time] = status_history[from].last[:start_date].hours_from(status_history[from].last[:end_date])
        end
        # Add status if it doesn't exist
        statuses << to
        status_history[to] = [] unless status_history.has_key?(to)
        status_history[to] << StatusIteration.new(date, nil, nil, @cur_assignee, @cur_sprint)
        @changes << Change.new(self, date, field, from, to, "Status changed from #{from} to #{to}")
      end

      # Track sprint inclusion / ejection
      if field == 'Sprint'
        if to.nil?
          s = "Removed from #{from}"
        else
          s = "Added to #{to}"
          @sprints << to
        end
        # Capture the change in sprint so that we can filter out in-sprint vs out-of sprint time in the future
        @cur_sprint = to
        @changes << Change.new(self, date, field, from, to, s)
      end

      # Track changes in story points
      if field == 'Story Points'
        @changes << Change.new(self, date, field, from, to, "Size changed from #{from} to #{to} points")
      end

      # Track the developer
      if field == 'assignee'
        @cur_assignee = to
        @contributors << to
        @changes << Change.new(self, date, field, from, to, "Assignee from #{from} to #{to}")
      end

    end


  end

end