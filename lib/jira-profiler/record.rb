module JiraProfiler

  # A record of a person, team, or projects performance for a unit of time
  class Record
    include Logger

    attr_reader :unit_of_time, :start_date, :end_date

    def initialize(unit_of_time, start_date, end_date)
      @unit_of_time = :day
      @start_date   = start_date
      @end_date     = end_date
      @fields = []
      @values = []
    end

    def fields()
      # statuses
      #   time in
      # created, updated, assigned, transitioned
    end

    def values()
    end

    def row()
    end

  end

end