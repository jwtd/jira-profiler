require 'spec_helper'

describe JiraProfiler do

  before do
    JiraProfiler.reset_configuration
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

  describe "#from_hash" do

    it "should construct the correct output file name from the app name" do

      c = JiraProfiler::Configuration.from_hash({:app_name => 'Foo App'})

      expect(c.app_name).to eq 'Foo App'
      expect(c.output_file).to eq 'foo-app_output'

    end

  end

  describe "#from_yaml_file" do

    it "should construct the correct output file name from the app name" do

      c = JiraProfiler::Configuration.from_hash({:app_name => 'Foo App'})

      expect(c.app_name).to eq 'Foo App'
      expect(c.output_file).to eq 'foo-app_output'

    end

  end

end