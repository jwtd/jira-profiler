module JiraProfiler

  class Change
    include Logger

    attr_reader :issue, :date, :field, :from, :to, :description, :elapsed_hours

    def initialize(issue, date, field, from, to, current_assignee, current_sprint)
      @event    = :unknown
      @issue    = issue
      @date     = date
      @field    = field
      @from     = from
      @to       = to
      @assignee = current_assignee
      @sprint   = current_sprint
      @elapsed_hours = nil

      # Track the developer
      if field == 'assignee'
        @from  = JiraProfiler::Cli.standardize_name(from)
        @to    = JiraProfiler::Cli.standardize_name(to)
        @event = :assigned
        @description = "Assignee from #{from} to #{to}"
      end

      # Track changes in issue status
      if field == 'status'
        @event = to.to_sym
        @description = "Status changed from #{from} to #{to}"
      end

      # Track what sprint this is in
      if field == 'Sprint'
        if to.nil?
          @event = :removed
          @description = "Removed from #{from}"
        else
          @event = :added
          @description = "Added to #{to}"
          #TODO: Add to sprint << to
        end
      end

      # Track changes in story points
      if field == 'Story Points'
        if from == ''
          @event = :sized
          @description = "Sized as #{to} points"
        else
          @event = :resized
          @description = "Resized from #{from} to #{to} points"
        end
      end

      # Record the activity
      JiraProfiler::User.find_by_username(assignee).record_change(self)
      issue.project.record_change(self)

    end

    # Convenience attribute to return project via parent issue
    def project
      @issue.project
    end


  end

end