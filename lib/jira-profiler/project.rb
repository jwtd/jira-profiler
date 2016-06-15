require 'active_support/all'
require 'set'
require 'pp'

module JiraProfiler

  class Project < JiraApiBase
    include Logger

    attr_reader :id, :key, :name, :description, :contributors

    @@project_cache = {}


    # Class methods ------------------


    class << self

      # Look up project by project id
      def find_by_id(id)
        find_by('id', id)
      end

      # Look up project by project key
      def find_by_key(key)
        find_by('key', key)
      end

      # Look up project by project name
      def find_by_name(name)
        find_by('name', name)
      end

      # Look up project by project id
      def find_by(attribute, value)
        if @@project_cache.has_key?(value)
          project = @@project_cache[value]
        else
          project_id = lookup_id_for(attribute, value)
          project = get_project(project_id)
        end
        return project
      end

      # Loop over all of the projects to find the id of the project whose attribute matches the value provided
      def lookup_id_for(attribute, value)
        return value if attribute == 'id'
        project_list = get("/rest/api/2/project")
        project_list.each do |project|
          return project['id'] if project[attribute] == value
        end
      end

      # Cache project instances to avoid rebuilding multiple times
      def get_project(id)
        project = new(get("/rest/api/2/project/#{id}"))
        @@project_cache[project.name] = project
        @@project_cache[project.id]   = project
        @@project_cache[project.key]  = project
        return project
      end

    end


    # Instance methods ------------------


    def initialize(options)

      # Get issues metadata
      @id   = options['id']
      @key  = options['key']
      @name = options['name']
      @description = options['description']
      #TODO: @versions = options['versions'].collect do {|v| v['name']}

      # Prepare references
      @issue_fields = nil
      @sprints = nil

    end


    # Lazy load by looping over all sprints
    def sprints
      if @sprint.nil?
        @sprints = ActiveSupport::OrderedHash.new()
        rapid_view = self.class.get("/rest/greenhopper/1.0/sprintquery/#{id}")
        rapid_view['sprints'].each do |item|
          sprint = Sprint.new(id, item['id'])
          @sprints[sprint.name] = sprint
        end
      end
      @sprints
    end


    # Returns all issues in project
    def issues
      if @issues.nil?
        @issues = {}
        max_result = 3
        jql = "/rest/api/2/search?jql=project=\"#{name}\" AND issuetype NOT IN (Epic, Sub-task)&expand=changelog&maxResults=#{max_result}"
        #r = nil
        #without_cache{ r = self.class.get("#{jql}&startAt=0") }
        r = self.class.get("#{jql}&startAt=0")
        pages = (r['total'] / max_result)
        (0..pages).each do |current_page|
          begin
            # If you can get the latest version of the last page, do so, otherwise load the cached version
            query = "#{jql}&startAt=#{(current_page * max_result)}"
            if current_page == pages
              #without_cache{ r = self.class.get(query) }
              r = self.class.get(query)
            else
              r = self.class.get(query)
            end
            r['issues'].each do |issue|
              # Cast raw response to Issue(), passing project reference into constructor
              issue['project'] = self
              @issues[issue['key']] = Issue.new(issue)
            end
          # rescue => exception
          #   puts "#{exception.message} (#{exception.class})"
          #   pp exception.backtrace
          end
        end
      end
      @issues
    end

    # The list of users who worked on this project
    def contributors
      if @contributors.nil?
        @contributors = Set.new()
        issues.each do |issue|
          @contributors.merge(issue.contributors)
        end
      end
      @contributors
    end


  end

end