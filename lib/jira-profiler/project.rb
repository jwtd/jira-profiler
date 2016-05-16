require 'httparty'

module JiraProfiler

  class Project

    include HTTParty
    base_uri 'virtru.atlassian.net'
    basic_auth ENV.fetch('JIRA_UN'), ENV.fetch('JIRA_PW')

    attr_reader :id, :name

    def initialize(project_name)
      @id   = nil
      @name = project_name
    end

  end

end