require 'active_support/all'
require 'pp'

module JiraProfiler

  class Project < JiraApiBase
    include Logger

    attr_reader :id, :name

    def initialize(project_name)
      logger.info "Initializing project '#{project_name}'"
      @id   = nil
      @name = project_name

      # Prepare a reference object to store result
      @sprints = nil

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


    def rapid_view
      self.class.get("/rest/greenhopper/1.0/sprintquery/#{id}")
    end


    def sprints
      # Lazy load by looping over all sprints
      @sprints unless @sprint.nil?
      @sprints = ActiveSupport::OrderedHash.new()
      rapid_view['sprints'].each do |item|
        sprint = Sprint.new(id, item['id'])
        @sprints[sprint.name] = sprint
      end
    end


    # Returns all issues in project
    def issues
      @issues unless @issues.nil?
      @issues = {}
      max_result = 3
      jql = "/rest/api/2/search?jql=project=\"#{name}\" AND issuetype NOT IN (Epic, Sub-task)&expand=changelog&maxResults=#{max_result}"
      without_cache{ r = self.class.get("#{jql}&startAt=0") }
      pages = (r['total'] / max_result)
      (0..pages).each do |current_page|
        begin
          # If you can get the latest version of the last page, do so, otherwise load the cached version
          query = "#{jql}&startAt=#{(p * max_result)}"
          if current_page == pages
            without_cache{ r = self.class.get(query) }
          else
            r = self.class.get(query)
          end
          r['issues'].each do |issue|
            # Cast raw response to Issue(), passing project reference into constructor
            issue['project'] = self
            @issues[issue['key']] = Issue.new(issue)
          end
        rescue
          puts "Unable to retrieve last page from cache or source: #{query}"
        end
      end
      @issues
    end


  end

end