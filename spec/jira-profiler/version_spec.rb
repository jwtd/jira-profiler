require 'spec_helper'

describe JiraProfiler::VERSION do
  it 'has a version number' do
    expect(JiraProfiler::VERSION::STRING).not_to be nil
    expect(JiraProfiler::VERSION::MAJOR).not_to be nil
    expect(JiraProfiler::VERSION::MINOR).not_to be nil
    expect(JiraProfiler::VERSION::PATCH).not_to be nil
  end
end