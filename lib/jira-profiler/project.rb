require 'active_support/all'

module JiraProfiler

  class Project < JiraApiBase
    include Logger

    attr_reader :id, :name

    def initialize(project_name)
      logger.info "Initializing project #{project_name}"
      @id   = nil
      @name = project_name

      # Prepare a reference object to store result
      @sprints = ActiveSupport::OrderedHash.new()
      @sprint_start_dates = {}

      # Loop over all views
      rapid_views = self.class.get("/rest/greenhopper/1.0/rapidview")
      rapid_views['views'].each do |view|
        logger.debug "Checking view: #{view}"
        if (view['name'] == project_name)
          puts "Initializing view #{view['name']}"
          @id = view['id']
        end
      end

    end


    def sprints
      # Lazy load by looping over all sprints
      @sprints unless @sprint_order.empty?
      rapid_view['sprints'].each do |sprint|
        sprint = Sprint.new(@project_board_id, s['id'])
        @sprints[sprint.name] = sprint
        @sprint_start_dates[sprint.start_date.strftime('%Y-%m-%d')] = sprint.name
      end
      @sprints
    end


    def rapid_view
      self.class.get("/rest/greenhopper/1.0/sprintquery/#{@project_board_id}")
    end


  end

end