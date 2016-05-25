# Reference: http://brandonhilkert.com/blog/ruby-gem-configuration-patterns/
require 'active_support/all'

module JiraProfiler

  # Module level access to configuration
  class << self
    attr_writer :configuration
  end

  # Allow block style configuration
  def self.configure
    yield(self.configuration)
  end

  # Lazy initialization of default config
  def self.configuration
    @configuration ||= Configuration.new()
  end

  # Allow configuration from hash
  def self.configure_from_hash(h)
    @configuration = Configuration.new(h)
  end

  # Allow configuration from yaml file
  def self.configure_from_yaml_file(f)
    @configuration = Configuration.from_yaml_file(f)
  end

  # Reset configuration
  def self.reset_configuration
    @configuration = Configuration.new
  end

  # Define the configuration options
  class Configuration

    attr_writer   :app_name             # Name of app
    attr_writer   :output_file          # Filename of data export
    attr_accessor :log_level            # :off, :all, :debug, :info, :warn, :error, :fatal
    attr_accessor :trace_exceptions     # Default is true
    attr_accessor :log_to_stdout        # Default is true
    attr_accessor :stdout_colors        # Default is :for_dark_backgrounds, :for_light_background, or custom by passing a hash that conforms to https://github.com/TwP/logging/blob/master/examples/colorization.rb
    attr_accessor :log_file             # Default is nil
    attr_accessor :log_file_layout      # :basic, :json, :yaml, or a pattern such as '[%d] %-5l: %m\n'
    attr_accessor :rolling_log_file_age # Default is false, options are false or 'daily', 'weekly', 'monthly' or an integer
    attr_accessor :rolling_log_limit    # Default is false, but any positive integer can be passed
    attr_accessor :growl_on_error       # Default is false

    attr_accessor :jira_un_env_key      # Default is JIRA_UN
    attr_accessor :jira_pw_env_key      # Default is JIRA_PW
    attr_accessor :use_cache            # Default is true


    # Specify the configuration defaults and support configuration via hash .configuration.new(config_hash)
    def initialize(options={})
      options={} unless options

      @config_file          = options[:config]
      @app_name             = options[:app_name]
      @output_file          = options[:output_file]

      @log_level            = options[:log_level]            || :debug
      @trace_exceptions     = options[:trace_exceptions]     || true
      @log_to_stdout        = options[:log_to_stdout]        || true
      @stdout_colors        = options[:stdout_colors]        || :for_dark_background
      @log_file             = options[:log_file]             || "#{app_name.to_dash_case}_log.txt"
      @log_file_layout      = options[:log_file_layout]      || '[%d] %-5l -- %c -- %m\n'
      @rolling_log_file_age = options[:rolling_log_file_age] || false
      @rolling_log_limit    = options[:rolling_log_limit]    || false
      @growl_on_error       = options[:growl_on_error]       || false

      @jira_un_env_key      = options[:jira_un_env_key]      || 'JIRA_UN'
      @jira_pw_env_key      = options[:jira_pw_env_key]      || 'JIRA_PW'
      @use_cache            = options[:use_cache]            || true

    end

    def app_name
      @app_name || self.to_s.gsub('#<', '').gsub(/(::.*)/, '').to_dash_case
    end

    def output_file
      @output_file || "#{app_name.to_dash_case}_output"
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

  end

end


