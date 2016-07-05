require 'pp'

module JiraProfiler

  # For Sprint

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

  # Issue Type
  #   #
  #   Sizes
  #   # Histogram
  #   Status
  #     # Entered
  #     # Exited
  #     Elapsed Time
  #   Points at start
  #   Points at end


  class Sprint < JiraApiBase
    include Logger

    attr_reader :project, :id, :name, :current_state, :start_date, :end_date, :complete_date,
                :completed_issues, :incomplete_issues, :punted_issues, :pulled_in_issues,
                :all_pts, :completed_pts, :incomplete_pts, :punted_pts, :pulled_in_pts

    # The list of sprints which are recorded in Jira (note, these dates may not be reliable if Jira isn't maintained religously)
    def initialize(options)

      @project    = options[:project]
      @id         = options[:id]
      @name       = options[:name]
      @start_date = options.fetch(:start_date)
      @end_date   = options.fetch(:end_date)
      @note       = options.fetch(:note)

      # Get list of issues in a sprint
      # /rest/api/latest/search?jql=sprint%3D<SPRINT_ID>&fields=<FIELDS YOU WANT>&maxResults=<SOME REASONABLE LIMIT>

      # Get sprint stats
      jira_sprint = self.class.get("/rest/greenhopper/1.0/rapid/charts/sprintreport?rapidViewId=#{project.id}&sprintId=#{id}")
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

      # "issuesCompletedInAnotherSprint"=>[],
      #     "completedIssuesInitialEstimateSum"=>{"text"=>"null"},
      #     "completedIssuesEstimateSum"=>{"text"=>"null"},
      #     "issuesNotCompletedInitialEstimateSum"=>{"value"=>1.0, "text"=>"1.0"},
      #     "issuesNotCompletedEstimateSum"=>{"value"=>1.0, "text"=>"1.0"},
      #     "allIssuesEstimateSum"=>{"value"=>1.0, "text"=>"1.0"},
      #     "puntedIssuesInitialEstimateSum"=>{"text"=>"null"},
      #     "puntedIssuesEstimateSum"=>{"text"=>"null"},
      #     "issuesCompletedInAnotherSprintInitialEstimateSum"=>{"text"=>"null"},
      #     "issuesCompletedInAnotherSprintEstimateSum"=>{"text"=>"null"},
      #     "issueKeysAddedDuringSprint"=>{"WS-132"=>true}}


      # Save sprint metadata
      @name              = metadata['name']
      @current_state     = metadata['state']
      @start_date        = Date.parse(metadata["startDate"]) unless metadata["startDate"] == 'None'        # "09/Jun/15 2:47 PM"
      @end_date          = Date.parse(metadata["endDate"]) unless metadata["endDate"] == 'None'            # "22/Jun/15 2:47 PM"
      @complete_date     = Date.parse(metadata["completeDate"]) unless metadata["completeDate"] == 'None' # "None"

      @completed_issues  = contents['completedIssues']
      @incomplete_issues = contents['incompletedIssues']
      @punted_issues     = contents['puntedIssues']
      @pulled_in_issues  = contents['issueKeysAddedDuringSprint']

      @all_pts           = contents['allIssuesEstimateSum']['value'].to_f
      @completed_pts     = contents['completedIssuesEstimateSum']['value'].to_f
      @incomplete_pts    = contents['issuesNotCompletedEstimateSum']['value'].to_f
      @punted_pts        = contents['puntedIssuesEstimateSum']['value'].to_f
      @pulled_in_pts     = pulled_in_pts

      @activity = {
        :assignees   => {},
        :issue_types => {},
        :calendar    => ActiveSupport::OrderedHash.new()
      }

    end

    # The number of days in the sprint
    def length
      end_date.days_from(start_date).to_i
    end


    def activity

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


    # Return number of bugs, stories, tasks
    # def issue_types
    # end
    #
    # def planned_work
    # end
    #
    # def unplanned_work
    # end
    #
    # def expansion
    # end
    #
    # def creep
    # end

  end

end