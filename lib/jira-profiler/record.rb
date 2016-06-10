module JiraProfiler

  # A record of a person, team, or projects performance for a unit of time
  class Record
    include Logger

    attr_reader :unit_of_time, :start_date, :end_date, :fields, :values

    def initialize(unit_of_time, start_date, end_date)
      @unit_of_time = :day
      @start_date   = start_date
      @end_date     = end_date
      @data = {}
    end

    def fields()
      # statuses
      #   time in
      # created, updated, assigned, transitioned
      @data.keys()
    end

    def values()
      @data.keys()
    end

  end

end