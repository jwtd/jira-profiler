require 'spec_helper'

describe JiraProfiler::Cli do

  describe 'profile' do

    command "#{Dir.pwd}/bin/jira profile -p \"Web Stack\""
    # file 'data2.txt' do
    #   "another thing #{Time.now}"
    # end
    its(:stdout) { is_expected.to include JiraProfiler::VERSION::STRING }
    its(:stderr) { is_expected.to eq '' }
    its(:exitstatus) { is_expected.to eq 0 }

    # it "" do
    #   is_expected.to match_fixture 'write_data'
    # end

  end

end