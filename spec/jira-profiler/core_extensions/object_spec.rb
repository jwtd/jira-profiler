require 'spec_helper'

describe CoreExtensions::Object do

  describe '.deep_symbolize_keys' do
    it 'should convert a hashes string keys to symbols' do

      h1 = {'foo'=>'bar', 'baz' => {'test'=>3}}
      h2 = h1.deep_symbolize_keys

      expect(h1.has_key?('foo')).to eq true
      expect(h1.has_key?(:foo)).to eq false
      expect(h1['baz'].has_key?(:test)).to eq false

      expect(h2.has_key?('foo')).to eq false
      expect(h2.has_key?(:baz)).to eq true
      expect(h2[:baz].has_key?(:test)).to eq true

    end
  end

end