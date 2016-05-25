module JiraProfiler

  class Sprint
    include Logger

    attr_reader :id, :name, :current_state, :start_date, :end_date, :complete_date,
                :completed_issues, :incomplete_issues, :punted_issues, :pulled_in_issues,
                :all_pts, :completed_pts, :incomplete_pts, :punted_pts, :pulled_in_pts

    def initialize(project_board_id, sprint_id)
      @logger = logger

      # Save identity
      @project_board_id = project_board_id
      @id               = sprint_id

      # Get sprint stats
      jira_sprint = self.class.get("/rest/greenhopper/1.0/rapid/charts/sprintreport?rapidViewId=#{@project_board_id}&sprintId=#{@id}")
      metadata = jira_sprint['sprint']
      contents = jira_sprint['contents']

      # Pulled in stories have to be queried separately
      pulled_in_issues = contents['issueKeysAddedDuringSprint']
      pulled_in_pts    = 0
      pulled_in_issues.keys.each do |issue_key|
        issue = self.class.get("/rest/api/2/issue/#{issue_key}")['fields']
        pts = issue['customfield_10004'].nil? ? 0 : issue['customfield_10004'].to_f
        pulled_in_pts += pts
      end

      # Save sprint metadata
      @name              = metadata['name']
      @current_state     = metadata['state']
      @start_date        = Date.parse(md["startDate"]) unless md["startDate"] == 'None'        # "09/Jun/15 2:47 PM"
      @end_date          = Date.parse(md["endDate"]) unless md["endDate"] == 'None'            # "22/Jun/15 2:47 PM"
      @complete_date     = Date.parse(md["completeDate"]) unless md["completeDate"] == 'None' # "None"
      @completed_issues  = contents['completedIssues']
      @incomplete_issues = contents['incompletedIssues']
      @punted_issues     = contents['puntedIssues']
      @pulled_in_issues  = contents['issueKeysAddedDuringSprint']
      @all_pts           = contents['allIssuesEstimateSum']['value'].to_f
      @completed_pts     = contents['completedIssuesEstimateSum']['value'].to_f
      @incomplete_pts    = contents['incompletedIssuesEstimateSum']['value'].to_f
      @punted_pts        = contents['puntedIssuesEstimateSum']['value'].to_f
      @pulled_in_pts     = pulled_in_pts

    end

    def completed_count
      completed_issues.size
    end

    def incomplete_count
      incomplete_issues.size
    end

    def punted_count
      punted_issues.size
    end

    def pulled_in_issues_count
      pulled_in_issues.size
    end

  end

end