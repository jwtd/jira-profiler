# Reference: http://brandonhilkert.com/blog/ruby-gem-configuration-patterns/
require 'active_support/all'

module JiraProfiler

  # Module level access to configuration
  class << self
    attr_writer :configuration

    # Allow configuration by passing a hash or by using block style
    def configure(h={})
      if block_given?
        yield(self.configuration)
      elsif h.has_key?(:config_file)
        @configuration = Configuration.from_yaml_file(h[:config_file])
      else
        @configuration = Configuration.new(h)
      end
    end

    # Lazy initialization of default config
    def configuration
      @configuration ||= Configuration.new()
    end

    # Reset configuration
    def reset_configuration
      configuration.reset
    end
  end

  # Define the configuration options
  class Configuration

    @@defaults = {
      :app_name         => self.to_s.gsub('#<', '').gsub(/(::.*)/, '').to_dash_case,
      :config_file      => "config.yml",
      :log_level        => :debug,     # :off, :all, :debug, :info, :warn, :error, :fatal
      :trace_exceptions => true,
      :log_to_stdout    => true,
      :stdout_colors    => :for_dark_background,      # Default is :for_dark_backgrounds, :for_light_background, or custom by passing a hash that conforms to https://github.com/TwP/logging/blob/master/examples/colorization.rb
      :log_file         => 'log.txt',
      :log_file_layout  => '[%d] %-5l -- %c -- %m\n', # :basic, :json, :yaml, or a pattern such as '[%d] %-5l: %m\n'
      :growl_on_error   => false,
      :rolling_log_limit    => false,  # Default is false, but any positive integer can be passed
      :rolling_log_file_age => false,  # Default is false, options are false or 'daily', 'weekly', 'monthly' or an integer

      :jira_un_env_key  => 'JIRA_UN',
      :jira_pw_env_key  => 'JIRA_PW',
      :use_cache        => true,
      :team_data_file   => 'team.json'
    }

    # Specify the configuration defaults and support configuration via hash .configuration.new(config_hash)
    def initialize(options={})
      @values = @@defaults.merge(options)
    end

    # All buld update of configuration
    def configure(options)
      @values.merge!(options)
    end

    # Reset configuration
    def reset
      @values = @@defaults.clone
    end

    # File constructor
    def self.from_yaml_file(config_filename)
      config_filepath = File.join(Dir.pwd, config_filename)
      unless File.exist?(config_filepath)
        raise "Configuration file does not exist #{config_filepath}"
      else
        self.new(YAML.load_file(config_filepath).symbolize_keys)
      end
    end

    # Bracket style accessor to values
    def [](field)
      @values[field.to_sym]
    end

    # Bracket style setter to values
    def []=(field, value)
      @values[field.to_sym] = value
    end


    # If a field isn't defined, check to see if its exists in @values
    def method_missing(method_sym, *arguments, &block)
      if @values.has_key?(method_sym)
        define_dynamic_config_field(method_sym)
        send(method_sym)
      end
    end

    protected

    # Create config field accessor and setter to avoid calling method_missing more than once
    def define_dynamic_config_field(method_sym)
      class_eval <<-RUBY
      def #{method_sym}
        @values[:#{method_sym}]
      end

      def #{method_sym}=(value)
        @values[:#{method_sym}] = value
      end
      RUBY
    end

  end

end


