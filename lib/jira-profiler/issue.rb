require 'set'

module JiraProfiler

  class Issue < JiraApiBase
    include Logger

    attr_reader :project, :id, :key, :type, :status, :status_cat,
                :created_at, :dev_started_at, :completed_at,
                :reporter, :creator, :assignee,
                :summary, :description, :epic, :epic_issue,
                :sprints, :components, :labels, :status_durations,
                :transitions, :contributors

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

      @created_at        = DateTime.parse(f['created'])
      @dev_started_at    = nil
      @review_started_at = nil
      @qa_started_at     = nil
      @completed_at      = nil

      @status_durations = {}
      @subtasks     = nil
      @sprints      = Set.new()
      @contributors = Set.new()
      @transitions  = []
      @transitions << Transition.new(@created_at, 'status', '', 'Open', 'Created as Open')

      cur_sprint   = nil
      cur_assignee = nil
      cur_status   = nil

      log = jira_issue['changelog']['histories'].each do |h|

        h['items'].each do |event|

          d     = DateTime.parse(h['created'])
          field = event['field']
          from  = event['fromString']
          to    = event['toString']

          # Track changes in issue status
          if field == 'status'

            # Add status if it doesn't exist
            @status_durations[to] = [] unless @status_durations.has_key?(to)

            # If this is the first time its been put in development
            if (to == 'In Development' and @dev_started_at.nil?)
              @dev_started_at = d
            end

            # If this is the first time its been put in review
            if (to == 'In Review' and @review_started_at.nil?)
              @review_started_on = d
            end

            # If this is the first time its been put in QA
            if (to == 'In QA' and @qa_started_at.nil?)
              @qa_started_at = d
            end

            # Capture time in each state and the number of times it was in that state
            unless cur_status.nil?
              # Check if status exists. If it does update a sumation field as well.
              @status_durations[cur_status[:name]] << {
                  :from => cur_status[:start],
                  :to => d,
                  :assignee => cur_assignee,
                  :sprint => cur_sprint
              }
            end

            # If this is the first time its been put in development
            if (to == 'Closed' or to == 'Resolved')
              @end_dev = d
              @completed_at = d
            end

            # Update current status
            s = "Status changed from #{from} to #{to}"
            cur_status = {
                :name => to,
                :start => d,
                :assignee => cur_assignee
            }
            @transitions << Transition.new(d, field, from, to, s)
          end

          # Track sprint inclusion / ejection
          if field == 'Sprint'
            if to.nil?
              s = "Removed from #{from}"
            else
              s = "Added to #{to}"
              @sprints << to
            end
            cur_sprint = to
            # Capture the change in sprint so that we can filter out in-sprint vs out-of sprint time in the future
            @status_durations[cur_status[:name]] << {
                :from => cur_status[:start],
                :to => d,
                :assignee => cur_assignee,
                :sprint => cur_sprint
            } unless cur_status.nil?
            @transitions << Transition.new(d, field, from, to, s)
          end

          # Track changes in story points
          if field == 'Story Points'
            s = "Size changed from #{from} to #{to} points"
            @transitions << Transition.new(d, field, from, to, s)
          end

          # Track the developer
          if field == 'assignee'
            s = "Assignee from #{from} to #{to}"
            cur_assignee = to
            # Capture the change in assignee
            unless cur_status.nil?
              # Check if status exists. If it does update a sumation field as well.
              @status_durations[cur_status[:name]] << {
                  :from => cur_status[:start],
                  :to => d,
                  :assignee => cur_assignee,
                  :sprint => cur_sprint
              }
            end
            @contributors << cur_assignee
            @transitions << Transition.new(d, field, from, to, s)
          end

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

    # Calculate time in each state
    def time_from_open2close
      difference_in_hours(s, dev_end) unless dev_end.nil? or dev_start.nil?
    end

    def time_in_development
      difference_in_hours(dev_start, dev_end)
    end

    def time_in_review
      difference_in_hours(dev_start, dev_end)
    end

    def time_in_qa
      difference_in_hours(dev_start, dev_end)
    end

  end

end