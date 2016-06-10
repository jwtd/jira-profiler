require 'spec_helper'

describe JiraProfiler::Team do

  before(:all) do
    @team = JiraProfiler::Team.new("Test Team", "spec/fixtures/team.json")
  end

  describe '.initialize' do
    it "should set name and load team data" do
      expect(@team.name).to eq 'Test Team'
    end
  end

  describe '.standardize_name' do
    it "should convert non-standard name to a standard" do
      expect(@team.standardize_name('Zack Nelson')).to eq 'Zack Nelson'
      expect(@team.standardize_name('Zachary Nelson')).to eq 'Zack Nelson'
    end
  end

end