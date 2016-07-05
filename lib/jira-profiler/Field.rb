
module JiraProfiler

  class Field

    attr_reader :json_field, :ui_label, :attr_sym, :type

    @@field_reference = nil

    class << self

      # The field reference for the system
      def field_reference
        if @field_reference.nil?
          @field_reference = {
              :ui_labels   => {},
              :json_fields => {},
              :attr_sym    => {}
          }
          r = get("/rest/api/2/field")
          r.each do |field_json|
            field = self.new(field_json)
            @field_reference[:ui_labels][field.ui_label]     = field
            @field_reference[:json_fields][field.json_field] = field
            @field_reference[:attr_syms][field.attr_sym]     = field
          end
        end
        @field_reference
      end

      # Bracket style search for field
      def [](name_or_sym_or_field)
        return field_reference[:attr_syms  ][name_or_sym_or_field] if @field_map[:attr_syms  ].has_key?(name_or_sym_or_field)
        return field_reference[:ui_labels  ][name_or_sym_or_field] if @field_map[:ui_labels  ].has_key?(name_or_sym_or_field)
        return field_reference[:json_fields][name_or_sym_or_field] if @field_map[:json_fields].has_key?(name_or_sym_or_field)
      end

    end

    def initialize(field_json)
      @json_field = field_json['key']
      @ui_label = field_json['name']
      @attr_sym = ui_label.to_snake_case.to_sym
      @type = field_json.has_key?('schema') ? field_json['schema']['type'] : nil
    end

  end


  class FieldHistory

    attr_reader :field, :history, :current_value, :created_at

    def initialize(field, current_value, created_at)
      @field = field
      @current_value = current_value
      @created_at    = created_at
      @elapsed_time  = nil
      @history = ActiveSupport::OrderedHash.new()
    end

    # TODO: This is kludgy. Simplify so that you don't have to calculate elapsed_time all the time
    def record_change(options)
      if @history.size > 0
        last = @history.values.last
        last[:end_date] = options[:start_date]
        last[:elapsed_time] = last[:start_date].hours_from(last[:end_date])
      end
      @history[options[:start_date]] = {
        :value      => options[:value],
        :start_date => options[:start_date],
        :end_date   => options.fetch(:end_date, Date.today),
        :sprint     => options.fetch(:sprint),
        :assignee   => options.fetch(:assignee)

      }
      last = history.values.last
      last[:elapsed_time] = last[:start_date].hours_from(last[:end_date])
      @current_value = options[:value]
    end

    def value_on(date)
      # Value is nil if date is before created date
      return nil if date < created_at
      value = current_value
      history.each do |date, change|
        return value if date > change[:date]
        value = change[:value]
      end
      return value
    end

    def periods_when_value_was(value)
      history.values.select do |period|
        period[:value] == value
      end
    end

  end

end
