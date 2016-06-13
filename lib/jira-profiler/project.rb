require 'active_support/all'
require 'set'
require 'pp'

module JiraProfiler

  class Project < JiraApiBase
    include Logger

    attr_reader :id, :key, :name, :description, :contributors

    @@projects = {}

    # Look up project by project name
    def self.find_by_name(project_name)
      if @@projects.has_key?(project_name)
        project = @@projects[project_name]
      else
        # Loop over all of the projects to find the matching project's id
        project_id = nil
        r = get("/rest/api/2/project")
        r.each do |project|
          project_id = project['id'] if project['name'] == project_name
        end
        project = self.new(get("/rest/api/2/project/#{project_id}"))
        @@projects[project.name] = project
        @@projects[project.id]   = project
        @@projects[project.key]  = project
      end
      return project
    end

    # Look up project by project id
    def self.find_by_key(project_key)
      if @@projects.has_key?(project_key)
        project = @@projects[project_key]
      else
        # Loop over all of the projects to find the matching project's id
        project_id = nil
        r = get("/rest/api/2/project")
        r.each do |project|
          project_id = project['id'] if project['key'] == project_key
        end
        project = self.new(get("/rest/api/2/project/#{project_id}"))
        @@projects[project.name] = project
        @@projects[project.id]   = project
        @@projects[project.key]  = project
      end
      return project
    end

    # Look up project by project id
    def self.find_by_id(project_id)
      if @@projects.has_key?(project_id)
        project = @@projects[project_id]
      else
        project = self.new(get("/rest/api/2/project/#{project_id}"))
        @@projects[project.name] = project
        @@projects[project.id]   = project
        @@projects[project.key]  = project
      end
      return project
    end

    def initialize(options)

      # Get issues metadata
      @id   = options['id']
      @key  = options['key']
      @name = options['name']
      #TODO: @versions = options['versions'].collect do {|v| v['name']}
      @description = options['description']
      @issue_types = options['issueTypes']

      # Get the issue types and custom field map
      # TODO: Should not do this every time we create an issue. Cache the results.
      @issue_fields = {}
      r = self.class.get("/rest/api/latest/issue/createmeta?projectKeys=#{key}&expand=projects.issuetypes.fields")
      r['projects'].first['issuetypes'].each do |type_data|
        type = type_data['name']
        @issue_fields[type] = {:keys => {}, :names => {}}
        type['fields'].each do |key, field|
          @issue_fields[type][:keys][key] = field['name']
          @issue_fields[type][:names][field['name']] = key
        end
      end

      # Prepare a reference object to store result
      @sprints = nil

      # # Loop over all views to find this project's rapid view
      # rapid_views = self.class.get("/rest/greenhopper/1.0/rapidview")
      # rapid_views['views'].each do |view|
      #   if (view['name'] == options[:project_name])
      #     id = view['id']
      #   end
      # end

    end

    def issue_types()
      @issue_fields.keys
    end

    def issue_fields(issue_type = nil)
      if issue_type.nil?
        @issue_fields
      else
        @issue_fields[issue_type]
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
      r = nil
      without_cache{ r = self.class.get("#{jql}&startAt=0") }
      pages = (r['total'] / max_result)
      (0..pages).each do |current_page|
        begin
          # If you can get the latest version of the last page, do so, otherwise load the cached version
          query = "#{jql}&startAt=#{(current_page * max_result)}"
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
        # rescue => exception
        #   puts "#{exception.message} (#{exception.class})"
        #   pp exception.backtrace
        end
      end
      @issues
    end


    def contributors
      # Lazy load by looping over all sprints
      @contributors unless @contributors.nil?
      @contributors = Set.new()
      issues.each do |issue|
        @contributors.merge(issue.contributors)
      end
    end


  end

end