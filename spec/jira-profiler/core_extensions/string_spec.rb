require 'spec_helper'

describe CoreExtensions::String do

  describe '.to_bool' do

    it 'should convert truth-y strings to true' do
      expect('true'.to_bool).to be true
      expect('t'.to_bool).to be true
      expect('yes'.to_bool).to be true
      expect('y'.to_bool).to be true
      expect('1'.to_bool).to be true
    end

    it 'should convert false-y strings to false' do
      expect('false'.to_bool).to be false
      expect('f'.to_bool).to be false
      expect('no'.to_bool).to be false
      expect('n'.to_bool).to be false
      expect('0'.to_bool).to be false
    end

  end
end