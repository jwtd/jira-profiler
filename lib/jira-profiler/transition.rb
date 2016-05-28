module JiraProfiler

  class Transition
    include Logger

    attr_reader :at, :field, :from, :to, :description

    def initialize(at, field, from, to, description)
      @at, @field, @description = at, field, description
      if field == 'assignee'
        @from, @to = Team.standardize(from), Team.standardize(to)
      else
        @from, @to = from, to
      end
    end

  end

end