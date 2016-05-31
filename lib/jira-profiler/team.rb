require 'json'

module JiraProfiler

  class Team
    include Logger

    attr :name, :members
    attr_reader :vacation_log, :employment_log

    def initialize(name, team_data_filepath = nil)

      @@name           = name
      @@members        = {}
      @@team_data      = {'aliases' => nil}
      @@vacation_log   = nil
      @@employment_log = nil

      if team_filepath.nil?
        logger.debug "No team data file provided"
      else
        Team.load_team_data(team_data_filepath)
        Team.load_vacation_log(team_data_filepath)
        Team.load_employment_log(team_data_filepath)
      end
    end

    class << self

      # Facilitate normalization of all versions of a team member's name to one value
      def standardize_name(name)
        return @team_data['aliases'].fetch(name, name)
      end

      # Reference for team data
      def load_team_data(log_filepath)
        if File.exists?(team_filepath)
          @team_data = JSON.parse(File.read(team_filepath))
        else
          logger.error "Could not find team data file at #{team_filepath}"
        end
      end

      # Reference of vacation time for each team member
      def load_vacation_log(log_filepath)
        @vacation_log = {}
        data = CSV.read(log_filepath, { encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all})
        data.each do |r|
          d = Date.new(r[:year], r[:month], r[:day])
          k = d.strftime('%Y.%m.%d')
          @vacation_log[r[:who]] = {} unless @vaction_log.has_key?(r[:who])
          @vacation_log[k] = [] unless @vaction_log.has_key?(k)
          @vacation_log[k] << r[:who]
        end
      end

      # Reference of employment dates for each team member
      def load_employment_log(log_filepath)
        @employment_log = {}
        data = CSV.read(log_filepath, { encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all})
        data.each do |r|
          @employment_log[r[:who]] = {
              :started => r[:started],
              :stopped => r[:stopped],
              :range   => (r[:started]..r[:stopped]) # Allows the use of the === comparison
          } unless @employment_log.has_key?(r[:who])
        end
      end

    end

  end

end