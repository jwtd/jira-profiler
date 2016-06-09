require 'set'

module JiraProfiler

  class Issue < JiraApiBase
    include Logger

    attr_reader :project, :id, :key, :type, :status, :@statuses, :status_cat,
                :created_at, :dev_started_at, :completed_at,
                :reporter, :creator, :assignee,
                :summary, :description,
                :epic, :epic_issue,
                :sprints, :components, :labels,
                :transitions, :contributors

    StatusIteration = Struct.new(:start_date, :end_date, :assignee, :sprint)

    # Given ID, Label, or json object
    def initialize(options)

      # If an id was provided, look it up, otherwise assume the option block is JSON returned from a JQL query
      if options.has_key?(:id)
        issue_id_or_label = options[:id]
        jira_issue = self.class.get("/rest/api/2/issue/#{issue_id_or_label}?expand=changelog")
      else
        jira_issue = options
      end

      f = jira_issue['fields']

      # Get issues metadata
      @project     = jira_issue['project']
      @id          = jira_issue['id']
      @key         = jira_issue['key']
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
      @subtasks     = nil
      @sprints      = Set.new()
      @contributors = Set.new()

      # History & Stats
      @created_at  = DateTime.parse(f['created'])
      @statuses    = {:last => nil}
      @transitions = []
      @cur_sprint   = nil
      @cur_assignee = nil
      @cur_status   = nil

      # Step through the issue's history and record transitions
      add_transition(@created_at, 'status', 'Open', 'Created as Open')

      # Analyze the history
      log = jira_issue['changelog']['histories'].each do |h|
        h['items'].each do |event|
          d     = DateTime.parse(event['created'])
          field = event['field']
          from  = event['fromString']
          to    = event['toString']
          add_transition(d, field, from, to)
        end
      end

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
    def accumulated_time_in_status(status, assignee = :all)
      @statuses[status][:itterationsv].inject(0) do |sum, i|
        (i.assignee == :all or i.assignee == assignee) ? sum + i.elapsed_time : sum
      end
    end

    # How much time passed between the first time a status was set and the last time
    def elapsed_time_in_status(status)
      difference_in_hours(statuses[status].first.start_time, statuses[status].last.end_time)
    end


    private


    def add_transition(d, field, from, to)

      # Track changes in issue status
      if field == 'status'
        # Set the ending date of the last status
        statuses[from].last[:end_date] = date if @statuses.has_key(from)
        # Add status if it doesn't exist
        statuses[to] = [] unless @statuses.has_key(to)
        statuses[to] << StatusIteration.new(date, nil, @cur_assignee, @cur_sprint)
        @transitions << Transition.new(self, d, field, from, to, "Status changed from #{from} to #{to}")
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
        @transitions << Transition.new(self, d, field, from, to, s)
      end

      # Track changes in story points
      if field == 'Story Points'
        @transitions << Transition.new(self, d, field, from, to, "Size changed from #{from} to #{to} points")
      end

      # Track the developer
      if field == 'assignee'
        @cur_assignee = to
        @contributors << cur_assignee
        @transitions << Transition.new(self, d, field, from, to, "Assignee from #{from} to #{to}")
      end

    end


  end

end