module JiraProfiler

  class Project < JiraApiBase
    include Logger

    attr_reader :id, :name

    def initialize(project_name)
      @logger = logger
      @id   = nil
      @name = project_name

      # Loop over all views
      rapid_views = self.class.get("/rest/greenhopper/1.0/rapidview")
      rapid_views['views'].each do |v|
        logger.debug "Checking view: #{v}"
        if (v['name'] == project_name)
          puts "Initializing view #{v['name']}"
          @id = v['id']
        end
      end

    end

  end

end