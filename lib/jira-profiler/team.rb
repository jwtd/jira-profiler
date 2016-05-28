module JiraProfiler

  class Team
    include Logger

    def initialize(name)
      @name = name
    end

    # Class level metho
    def self.standardize(v)
      return 'Zack Nelson' if v == 'Zachary Nelson'
      return 'Ray Gonzales' if v == 'Raymond Gonzales'
      return v
    end

  end

end