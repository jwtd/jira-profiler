module JiraProfiler

  # A record of a person, team, or projects performance for a unit of time
  class Record
    include Logger

    attr_reader :label, :unit_of_time, :start_date, :end_date

    def initialize(label, unit_of_time, start_date, end_date)
      label        =
      unit_of_time =
      start_date   =
      end_date     =
    end

    # Capture and measure the item
    def assignments
    end

    def issues
    end

    # Epcis, stories, defects, tasks
    def issue_types
    end

    # Time spent in each status
    def statuses
    end

    def created
    end

    def assigned
    end

    def updated
    end

    def closed
    end

  end

end