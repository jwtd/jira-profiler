require 'spec_helper'

describe JiraProfiler::Logger do

  before do
    Logging.reset
  end

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

    context "when configured to log to file" do
      it "should create a log file named after the app" do
        JiraProfiler.configure_global_logger(:log_to_file => true)
        expect(File.file?(Logging.logger.root.appenders[1].name)).to eq true
      end
    end

  end

end