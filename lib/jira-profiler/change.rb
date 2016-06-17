module JiraProfiler

  class Change
    include Logger

    attr_reader :issue, :date, :field, :from, :to, :description

    def initialize(issue, date, field, from, to, description)
      @issue       = issue
      @date        = date
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
      @issue.project
    end

  end

end