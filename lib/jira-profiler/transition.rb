module JiraProfiler

  class Transition
    include Logger

    attr_reader :issue, :at, :field, :from, :to, :description

    def initialize(issue, at, field, from, to, description)
      @issue       = issue
      @at          = at
      @field       = field
      @description = description
      if field == 'assignee'
        @from, @to = JiraProfiler.standardize_name(from), JiraProfiler.standardize_name(to)
      else
        @from, @to = from, to
      end
    end

    # Convenience attribute to return project via parent issue
    def project
      @issue.project
    end

  end

end