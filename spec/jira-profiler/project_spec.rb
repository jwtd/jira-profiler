require 'spec_helper'

describe JiraProfiler::Project do

  # before(:all) do
  #   @project = JiraProfiler::Project.find_by_name('Web Stack')
  # end

  describe '#find_by_name' do
    it "should find the project in Jira by the project name" do
      project = JiraProfiler::Project.find_by_name('Web Stack')
      expect(project.name).to eq 'Web Stack'
      expect(project.key).to eq 'WS'
      expect(project.id).to eq '11300'
    end
  end

  describe '#find_by_key' do
    it "should find the project in Jira by the project key" do
      project = JiraProfiler::Project.find_by_key('WS')
      expect(project.name).to eq 'Web Stack'
      expect(project.key).to eq 'WS'
      expect(project.id).to eq '11300'
    end
  end

  describe '#find_by_id' do
    it "should find the project in Jira by the project id" do
      project = JiraProfiler::Project.find_by_id(11300)
      expect(project.name).to eq 'Web Stack'
      expect(project.key).to eq 'WS'
      expect(project.id).to eq '11300'
    end
  end

  describe '.schedule' do
    it "should import the project schedule from the specified file" do
      project = JiraProfiler::Project.find_by_name('Web Stack')
      expect(project.schedule.keys.first).to eq '2014.05.06'

      sprint = project.schedule['2015.02.03']
      pp sprint
      expect(sprint.label).to eq '46'
      expect(sprint.from_date.strftime('%m/%d/%y')).to eq '02/03/15'
      expect(sprint.to_date.strftime('%m/%d/%y')).to eq '02/19/15'
      expect(sprint.note).to eq 'Payam was gone for 1 week'
    end
  end

end