require 'spec_helper'

describe JiraProfiler::Logger do

  describe '#global_logger_configured?' do

    it "should respond false until first time logger is accessed" do
      expect(JiraProfiler.global_logger_configured?).to eq false
      JiraProfiler.configure_global_logger
      expect(JiraProfiler.global_logger_configured?).to eq true
    end

  end

  describe '#configure_global_logger' do

    it "should configure the global logger with default values" do
      JiraProfiler.configure_global_logger
      expect(Logging.logger.root.info?).to eq true
      expect(Logging.logger.root.caller_tracing).to eq true
      expect(Logging.logger.root.appenders[0].name).to eq "stdout"
      expect(Logging.logger.root.appenders[0].layout.pattern).to eq "[%d] %-5l -- %c : %m\n"
    end

  end

end