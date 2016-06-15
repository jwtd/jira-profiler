require 'spec_helper'

describe JiraProfiler::Issue do

  before(:all) do
    issue_json = JSON.parse(File.open('spec/fixtures/issue.json').read)
    @issue = JiraProfiler::Issue.new(issue_json)
  end

  describe '#find_by' do
    it "should find an issue by its issue id" do
      i = JiraProfiler::Issue.find_by(26336)
      expect(i.key).to eq 'WS-3531'
    end
    it "should find an issue by its label" do
      i =  JiraProfiler::Issue.find_by('WS-3531')
      expect(i.key).to eq 'WS-3531'
    end
  end

  describe '#field_reference' do
    it "should return a reference map of issue fields " do
      fields = JiraProfiler::Issue.field_reference
      expect(fields.keys.size).to eq 84
      field = fields['customfield_10008']
      expect(field.json_field).to eq 'customfield_10008'
      expect(field.ui_label).to eq 'Epic Link'
      expect(field.attr_sym).to eq :epic_link
    end
  end

  describe '.initialize' do
    it "should fetch the issues details from Jira" do
      expect(@issue.project.name).to eq 'Web Stack'
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

  describe '.status' do
    it "should return the issues current status" do
      expect(@issue.status).to eq "Closed"
    end
  end

  describe '.epic_link' do
    it "should be a dynamicly created accessor for a custom field" do
      expect(@issue.epic_link).to eq "PM-96"
    end
  end

  describe '.votes' do
    it "should be a dynamicly created accessor that returns an integer" do
      expect(@issue.votes).to eq 0
    end
  end

  describe '.creator' do
    it "should be a dynamicly created accessor that returns a users name" do
      expect(@issue.creator).to eq 'Jordan Duggan'
    end
  end

  describe '.attachment' do
    it "should be a dynamicly created accessor that returns an array of file names" do
      expect(@issue.attachment).to eq ["chrome.zip", "Screenshot 2016-04-13 14.42.34.png", "Screenshot 2016-04-13 14.42.34.png"]
    end
  end

  describe '.progress' do
    it "should be a dynamicly created accessor that returns a hash from the raw json" do
      expect(@issue.progress["progress"]).to eq 0
      expect(@issue.progress["total"]).to eq 0
    end
  end

end