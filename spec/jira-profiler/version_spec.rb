require 'spec_helper'

describe JiraProfiler::VERSION do
  it 'has a version number' do
    expect(JiraProfiler::VERSION::STRING).not_to be nil
  end
end