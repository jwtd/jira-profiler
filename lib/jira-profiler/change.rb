module JiraProfiler

  class Change
    include Logger

    attr_reader :issue, :at, :field, :from, :to, :description

    def initialize(issue, at, field, from, to, description)
      @issue       = issue
      @at          = at
      @field       = field
      @description = description
      if field == 'assignee'
        @from, @to = JiraProfiler::Cli.standardize_name(from), JiraProfiler::Cli.standardize_name(to)
      else
        @from, @to = from, to
      end
    end

    # Convenience attribute to return project via parent issue
    def project
      @issue.project .team.standardize_name(name)
    end

  end

end