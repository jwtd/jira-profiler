require 'set'
require 'pp'

module JiraProfiler

  class Issue < JiraApiBase
    include Logger

    attr_reader :project, :id, :key, :type,
                :statuses, :status_history, :status_cat,
                :sprints, :changes, :contributors

    @@field_reference = nil

    # TODO: May be better of making this a class
    Field = Struct.new(:json_field, :ui_label, :attr_sym, :type)

    StatusIteration = Struct.new(:start_date, :end_date, :elapsed_time, :assignee, :sprint)


    # Class methods ------------------


    class << self

      # Look up project by project name
      def find_by(issue_id_or_label)
        new(get("/rest/api/2/issue/#{issue_id_or_label}?expand=changelog"))
      end

      # The field reference for the system
      def field_reference
        if @@field_reference.nil?
          @@field_reference = {}
          r = get("/rest/api/2/field")
          r.each do |field|
            type =  field.has_key?('schema') ? field['schema']['type'] : nil
            @@field_reference[field['key']] = Field.new(
              field['key'],
              field['name'],
              field['name'].to_snake_case.to_sym,
              type
            )
          end
        end
        @@field_reference
      end

    end


    # Instance methods ------------------


    # Given ID, Label, or json object
    def initialize(options)

      # If an id was provided, look it up, otherwise assume the option block is JSON returned from a JQL query
      @project = JiraProfiler::Project.find_by_name(options['fields']['project']['name'])

      # Get issues metadata
      f            = options['fields']
      @id          = options['id']
      @key         = options['key']
      @type        = f['issuetype']['name']
      @status_cat  = f['status']['statusCategory']['name']


      # Associations
      @comments     = f['comment']['comments'] if f['comment']
      @subtasks     = nil
      @sprints      = Set.new()
      @contributors = Set.new()

      # History & Stats
      @created_at     = DateTime.parse(f['created'])
      @statuses       = Set.new()
      @status_history = {}
      @changes        = []

      # Lookup and associate the value of each field with the name in the reference
      @field_map = {
        :ui_labels   => {},
        :json_fields => {},
        :attr_syms   => {}
      }
      f.keys.each do |field_key|
        field = self.class.field_reference[field_key]
        value = resolve_value(f[field.json_field])
        @field_map[:ui_labels][ui_label] = value
        @field_map[:json_fields][field.json_field] = value
        @field_map[:attr_syms][field.attr_sym] = value
      end

      # Step through the issue's history and record transitions
      record_change(@created_at, 'status', '', 'Open')

      # Analyze the history
      r = options['changelog']['histories']
      r.each do |h|
        date = DateTime.parse(h['created'])
        h['items'].each do |event|
          field = event['field']
          from  = event['fromString']
          to    = event['toString']
          record_change(date, field, from, to)
        end
      end

    end

    # Bracket style search for field
    def [](name_or_sym_or_field)
      return @field_map[:ui_labels  ][name_or_sym_or_field] if @field_map[:ui_labels  ].has_key?(name_or_sym_or_field)
      return @field_map[:json_fields][name_or_sym_or_field] if @field_map[:json_fields].has_key?(name_or_sym_or_field)
      return @field_map[:attr_syms  ][name_or_sym_or_field] if @field_map[:attr_syms  ].has_key?(name_or_sym_or_field)
    end

    # Return boolean based on presence of a field
    def has_field?(name_or_sym_or_field)
      (not self[name_or_sym_or_field].nil?)
    end

    # Return the value of a field or if its nil, the default
    def fetch(name_or_sym_or_field, default)
      self[name_or_sym_or_field] || default
    end

    # Get the list of custom fields from the project config
    def fields
      @field_map[:ui_labels].keys
    end

    # If a field isn't defined, check to see if its exists and create an accessor for it
    def method_missing(method_sym, *arguments, &block)
      if has_field?(method_sym) and not [:issuetype, :changelog, :comments, :issuelinks].include?(method_sym)
        define_dynamic_field(method_sym)
        send(method_sym)
      end
    end

    # Returns all subtasks beloning to a project
    def subtasks
      if @subtasks.nil?
        @subtasks = {}
        jql = "/rest/api/2/search?jql=parent=\"#{@key}\"&expand=changelog&maxResults=200"
        r = self.class.get(jql)
        r['issues'].each do |issue|
          # Cast raw response to Issue()
          @subtasks[issue['key']] = Issue.new(issue)
        end
      end
      @subtasks
    end

    # How much time was spent in each of the statuses
    def accumulated_hours_in_status(status, assignee = :all)
      status_history[status].inject(0) do |sum, i|
        sum + i.elapsed_time if assignee == :all or assignee == i.assignee
      end
    end

    # How much time passed between the first time a status was set and the last time
    def elapsed_hours_in_status(status)
      status_history[status].first.start_date.hours_from(status_history[status].last.end_date)
    end


    private


    # Create config field accessor and setter to avoid calling method_missing more than once
    def define_dynamic_field(method_sym)
      class_eval <<-RUBY
        def #{method_sym}
          @field_map[:attr_syms][:#{method_sym}]
        end
      RUBY
    end

    # Extract the human readable value from the fields json
    def resolve_value(data)
      if data.is_a? Array
        v = data.collect {|item| resolve_value(item)}
      else
        v = build_value(data)
      end
      return v
    end

    # Search for the value fields in the order of relevance or return the raw json if none are found
    def build_value(data)
      if data.respond_to? :has_key?
        ['displayName','name','filename','votes','value'].each do |field|
          return data[field] if data.has_key?(field)
        end
      end
      return data
    end

    # Recrods relevant changes, but not all items in history
    def record_change(date, field, from, to)

      # Track changes in issue status
      if field == 'status'
        # Set the ending date of the last status
        if status_history.has_key?(from)
          status_history[from].last[:end_date] = date
          status_history[from].last[:elapsed_time] = status_history[from].last[:start_date].hours_from(status_history[from].last[:end_date])
        end
        # Add status if it doesn't exist
        statuses << to
        status_history[to] = [] unless status_history.has_key?(to)
        status_history[to] << StatusIteration.new(date, nil, nil, @cur_assignee, @cur_sprint)
        @changes << Change.new(self, date, field, from, to, "Status changed from #{from} to #{to}")
      end

      # Track sprint inclusion / ejection
      if field == 'Sprint'
        if to.nil?
          s = "Removed from #{from}"
        else
          s = "Added to #{to}"
          @sprints << to
        end
        # Capture the change in sprint so that we can filter out in-sprint vs out-of sprint time in the future
        @cur_sprint = to
        @changes << Change.new(self, date, field, from, to, s)
      end

      # Track changes in story points
      if field == 'Story Points'
        @changes << Change.new(self, date, field, from, to, "Size changed from #{from} to #{to} points")
      end

      # Track the developer
      if field == 'assignee'
        @cur_assignee = to
        @contributors << to
        @changes << Change.new(self, date, field, from, to, "Assignee from #{from} to #{to}")
      end

      # Record the activity
      User.find_by_username(@cur_assignee).record_assignment(@changes.last)

    end


  end

end