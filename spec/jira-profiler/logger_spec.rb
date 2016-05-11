require 'spec_helper'

describe JiraProfiler::Logger do

  describe '#global_logger_configured?' do
    it "should respond false until global logger has been configured" do
      expect(JiraProfiler.global_logger_configured?).to eq false
      JiraProfiler.configure_global_logger
      expect(JiraProfiler.global_logger_configured?).to eq true
    end
  end

  describe '#configure_global_logger' do

    it "should construct the correct output file name from the app name" do
      pending
    end

  end

end