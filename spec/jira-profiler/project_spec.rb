require 'spec_helper'

describe JiraProfiler::Project do

  describe '.initialize' do
    it "should fetch the project's details from Jira" do
      p = JiraProfiler::Project.new('Web Stack')
      expect(p.name).to eq 'Web Stack'
      expect(p.id).to eq 26
    end
  end

end