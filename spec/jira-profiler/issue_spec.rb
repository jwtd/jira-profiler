require 'spec_helper'

describe JiraProfiler::Issue do

  before(:all) do
    issue_json = JSON.parse(File.open('spec/fixtures/issue.json').read)
    @issue = JiraProfiler::Issue.new(issue_json)
  end

  describe '.initialize' do
    it "should fetch the issues details from Jira" do
      expect(@issue.project).to eq 'Web Stack'
      expect(@issue.key).to eq 'WS-3531'
      #expect(@transitions.size).to eq 19
    end
  end

  # describe '.subtasks' do
  #   it "should fetch the subtasks from Jira" do
  #     pending
  #   end
  # end
  #
  # describe '.accumulated_time_in_status' do
  #   it "should return the accumulated hours spent in a status" do
  #     pending
  #   end
  # end
  #
  # describe '.elapsed_time_in_status' do
  #   it "should return the hours between the first time a status was set and the last" do
  #     pending
  #   end
  # end

end