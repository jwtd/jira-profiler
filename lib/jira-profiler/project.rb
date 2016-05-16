module JiraProfiler

  class Project < JiraApiBase

    attr_reader :id, :name

    def initialize(project_name)
      @id   = nil
      @name = project_name
    end

  end

end