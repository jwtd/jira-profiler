require 'spec_helper'

describe JiraProfiler::Cli do

  describe 'profile' do

    command "#{Dir.pwd}/bin/jira profile -p \"Web Stack\" -d \"spec/fixtures/team.json\""
    # file 'data2.txt' do
    #   "another thing #{Time.now}"
    # end
    its(:stdout) { is_expected.to include JiraProfiler::VERSION::STRING }
    its(:stderr) { is_expected.to eq '' }
    its(:exitstatus) { is_expected.to eq 0 }

  end

  describe '.standardize_name' do
    it "should convert non-standard name to a standard" do
      expect(JiraProfiler::Cli.standardize_name('Zack Nelson')).to eq 'Zack Nelson'
      expect(JiraProfiler::Cli.standardize_name('Zachary Nelson')).to eq 'Zachary Nelson'
    end
  end

end