require 'time_difference'

module CoreExtensions
  module Time

    def years_from(t)
      TimeDifference.between(self, t).in_years
    end

    def months_from(t)
      TimeDifference.between(self, t).in_months
    end

    def weeks_from(t)
      TimeDifference.between(self, t).in_weeks
    end

    def days_from(t)
      TimeDifference.between(self, t).in_days
    end

    def hours_from(t)
      TimeDifference.between(self, t).in_hours
    end

    def minutes_from(t)
      TimeDifference.between(self, t).in_minutes
    end

    def seconds_from(t)
      TimeDifference.between(self, t).in_seconds
    end

    def as_sortable_timestamp
      self.strftime('%Y.%m.%d.%H.%M.%s')
    end

    def as_sortable_datetime
      self.strftime('%Y.%m.%d.%H.%M')
    end

    def as_sortable_date
      self.strftime('%Y.%m.%d')
    end

    def weekend?
      (self.saturday? or self.sunday?)
    end

    def weekday?
      (not self.weekend?)
    end

    def time_from(t)
      TimeDifference.between(self, t).humanize
    end

    def time_components_from(t)
      TimeDifference.between(self, t).in_each_component
    end

  end
end