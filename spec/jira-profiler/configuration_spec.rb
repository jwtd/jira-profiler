require 'spec_helper'

describe JiraProfiler do

  before do
    JiraProfiler.reset_configuration
  end

  describe "#new" do
    it "should construct the correct output file name from the app name" do
      c = JiraProfiler::Configuration.new(:app_name => 'Foo App')
      expect(c.app_name).to eq 'Foo App'
      expect(c.output_file).to eq 'foo-app_output'
    end
  end

  describe "#configure" do
    it "should construct the correct output file name from the app name" do
      c = JiraProfiler.configuration
      expect(c.output_file).to eq('jira-profiler_output')
      JiraProfiler.configure do |config|
        config.app_name = 'Foo App'
      end
      expect(c.app_name).to eq 'Foo App'
      expect(c.output_file).to eq 'foo-app_output'
    end
  end

  describe "#configure_from_hash" do
    it "should construct the correct output file name from the app name" do
      c = JiraProfiler.configure_from_hash({:app_name => 'Foo App'})
      expect(c.app_name).to eq 'Foo App'
      expect(c.output_file).to eq 'foo-app_output'
    end
  end

  describe "#from_yaml_file" do
    it "should construct the correct output file name from the app name" do
      c = JiraProfiler.configure_from_yaml_file('spec/fixtures/config.yml')
      expect(c.stdout_colors).to eq 'for_light_background'
    end
  end

  describe "#reset_configuration" do
    it "should reset the configuration" do
      c = JiraProfiler.configure_from_hash({:app_name => 'Foo App'})
      expect(c.app_name).to eq 'Foo App'
      JiraProfiler.reset_configuration
      expect(c.output_file).to eq 'foo-app_output'
    end
  end

end