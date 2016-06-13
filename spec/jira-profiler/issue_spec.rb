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
      expect(@issue.changes.size).to eq 25
    end
  end

  describe '.subtasks' do
    it "should fetch the subtasks from Jira" do
      expect(@issue.subtasks.size).to eq 0
    end
  end

  describe '.type' do
    it "should return the issue type" do
      expect(@issue.type).to eq "Story"
    end
  end

  describe '.status' do
    it "should return the issues current status" do
      expect(@issue.status).to eq "Closed"
    end
  end

  describe '.statuses' do
    it "should return an array containing the statuses which this issue went through" do
      expect(@issue.statuses.size).to eq 7
      expect(@issue.statuses.to_a).to eq ["Open", "In Development", "Ready for Review", "Resolved", "Reopened", "Closed", "Review Done"]
    end
  end

  describe '.accumulated_hours_in_status' do
    it "should return the accumulated hours spent in a status" do
      expect(@issue.accumulated_hours_in_status('Open')).to eq 118.99 # (93.32 + 25.67)
    end
  end

  describe '.elapsed_hours_in_status' do
    it "should return the hours between the first time a status was set and the last" do
      expect(@issue.elapsed_hours_in_status('Open')).to eq 119.27
    end
  end

  describe '.epic' do
    it "should return the issue's epic" do
      expect(@issue.epic).to eq "Story"
    end
  end

end