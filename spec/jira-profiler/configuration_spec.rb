require 'spec_helper'

describe JiraProfiler do

  before do
    JiraProfiler.reset_configuration
  end

  describe "#configure" do

    it "should allow fields to be set using block style" do
      c = JiraProfiler.configuration
      expect(c.app_name).to eq('jira-profiler')
      JiraProfiler.configure do |config|
        config.app_name = 'Foo App'
      end
      expect(c.app_name).to eq 'Foo App'
    end

    it "should allow fields to be set using hash parameters" do
      c = JiraProfiler.configure(:app_name => 'Bar App')
      expect(c.app_name).to eq 'Bar App'
    end

    it "should allow fields to be set using a config file" do
      c = JiraProfiler.configure(:config_file => 'spec/fixtures/config.yml')
      expect(c.stdout_colors).to eq 'for_light_background'
    end

  end

  describe "#configuration" do
    it "should return the default configuration" do
      c = JiraProfiler.configuration
      expect(c.app_name).to eq 'jira-profiler'
    end

    it "should allow acces through the config alias" do
      c = JiraProfiler.config
      expect(c.app_name).to eq 'jira-profiler'
    end

    it "should provide access to fields with brackets" do
      c = JiraProfiler.configuration
      expect(c[:app_name]).to eq 'jira-profiler'
      c[:app_name] = 'BAR'
      expect(c[:app_name]).to eq 'BAR'
    end

  end

  describe "#reset_configuration" do
    it "should reset the configuration" do
      c = JiraProfiler.configure(:app_name => 'Foo App')
      expect(c.app_name).to eq 'Foo App'
      JiraProfiler.reset_configuration
      expect(c.app_name).to eq 'jira-profiler'
    end
  end



  describe JiraProfiler::Configuration do

    describe ".[]" do
      it "should allow access to fields using brackets" do
        c = JiraProfiler.configure(:app_name => 'Foo App')
        expect(c[:app_name]).to eq 'Foo App'
        c[:app_name] = 'Bar App'
        expect(c.app_name).to eq 'Bar App'
      end
    end

    describe ".update" do
      it "should allow bulk updating of fields" do
        c = JiraProfiler.configure(:app_name => 'Foo App')
        expect(c.app_name).to eq 'Foo App'
        c.update(:app_name => 'Bar App')
        expect(c.app_name).to eq 'Bar App'
      end
    end

  end

end