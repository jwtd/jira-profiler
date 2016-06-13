require 'spec_helper'

describe JiraProfiler::Project do

  before(:all) do
    @project = JiraProfiler::Project.find_by_name('Web Stack')
  end

  describe '#find_by_name' do
    it "should find the project in Jira by the project name" do
      JiraProfiler::Project.find_by_name('Web Stack')
      expect(@project.name).to eq 'Web Stack'
      expect(@project.key).to eq 'WS'
      expect(@project.id).to eq 11300
    end
  end

  describe '#find_by_key' do
    it "should find the project in Jira by the project key" do
      JiraProfiler::Project.find_by_key('WS')
      expect(@project.name).to eq 'Web Stack'
      expect(@project.key).to eq 'WS'
      expect(@project.id).to eq 11300
    end
  end

  describe '#find_by_id' do
    it "should find the project in Jira by the project id" do
      JiraProfiler::Project.find_by_key(11300)
      expect(@project.name).to eq 'Web Stack'
      expect(@project.key).to eq 'WS'
      expect(@project.id).to eq 11300
    end
  end

  describe '.issue_types' do
    it "should return an array of the project's issue types" do
      expect(@project.issue_types).to eq {}
    end
  end

  describe '.issue_fields' do
    it "should return a hash of the project's issue types associated with their fields" do
      expect(@project.issue_fields).to eq {}
    end
    it "should return a hash of the specified issue type's fields " do
      expect(@project.issue_fields('Story')).to eq {}
    end
  end

end