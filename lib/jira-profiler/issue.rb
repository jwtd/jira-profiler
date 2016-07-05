require 'set'
require 'pp'

module JiraProfiler

  # For issue
  #   Age in days
  #   Dev time in days
  #   Spanned across X sprints (incompleted = S-1)
  #   Time spent in development
  #   Time spent in review
  #   Time spent in QA
  #   Scheduled vs non-scheduled

  class Issue < JiraApiBase
    include Logger

    attr_reader :project, :id, :key, :type,
                :changes, :statuses, :field_history, :status_category,
                :sprints, :current_sprint,
                :assignee, :contributors

    @@field_reference = nil

    # Class methods ------------------


    class << self

      # Look up project by project name
      def find_by(issue_id_or_label)
        new(get("/rest/api/2/issue/#{issue_id_or_label}?expand=changelog"))
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
      @status      = f['status']['name']
      @status_category = f['status']['statusCategory']['name']

      # Associations
      @comments       = f['comment']['comments'] if f['comment']
      @subtasks       = nil
      @current_sprint = nil
      @contributors   = Set.new()
      @current_assignee = nil

      # History & Stats
      @created_at     = DateTime.parse(f['created'])
      @changes        = []
      @fields         = {}  # TODO: Should merge changes and field_history

      # Lookup and associate the value of each field with the name in the reference
      f.keys.each do |field_key|
        field = JiraProfiler::Field[field_key]
        value = resolve_value(f[field.json_field])
        @fields[field.attr_sym] = JiraProfiler::FieldHistory.new(field, value, created_at)
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


    # Returns all subtasks beloning to a project
    def subtasks
      if @subtasks.nil?
        @subtasks = {}
        jql = "/rest/api/2/search?jql=parent=\"#{@key}\"&expand=changelog&maxResults=200"
        r = self.class.get(jql)
        r['issues'].each do |issue|
          # Cast raw response to Issue()
          @subtasks[issue['key']] = Issue.new(issue)
          # TODO: Merge subtask history into this issues history
        end
      end
      @subtasks
    end


    # Bracket style search for field
    def [](name_or_sym_or_field)
      fields[JiraProfiler::Field[name_or_sym_or_field].attr_sym].current_value
    end


    # Return the value of a field or if its nil, the default
    def fetch(name_or_sym_or_field, default)
      self[name_or_sym_or_field] || default
    end


    # Return boolean based on presence of a field
    def has_field?(name_or_sym_or_field)
      (not self[name_or_sym_or_field].nil?)
    end


    # List of symbols for the fields on this issue
    def field_list
      fields.keys
    end


    # If a field isn't defined, check to see if its exists and create an accessor for it
    def method_missing(method_sym, *arguments, &block)
      if has_field?(method_sym) and not [:issuetype, :changelog, :comments, :issuelinks].include?(method_sym)
        define_dynamic_field(method_sym)
        send(method_sym)
      end
    end


    # How much time was spent in each of the statuses
    def accumulated_hours_in_status(status, assignee = :all)
      fields['status'].periods_when_value_was(status).inject(0) do |sum, period|
        sum + period[:elapsed_time] if assignee == :all or assignee == period[:assignee]
      end
    end


    # How much time passed between the first time a status was set and the last time
    def elapsed_hours_in_status(status)
      periods = fields['status'].periods_when_value_was(status)
      periods.first[:start_date].hours_from(periods.last[:end_date])
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

      fields[field].record_change(
        :value      => to,
        :start_date => date,
        :sprint     => current_sprint,
        :assignee   => assignee)

      # Track sprint inclusion / ejection
      if field == 'Sprint'
        @current_sprint = to
      end

      # Track the developer
      if field == 'assignee'
        @contributors << to unless to.nil?
        @current_assignee = to
      end

      @changes << Change.new(self, date, field, from, to, @current_assignee, @current_sprint)

    end


  end

end