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

  describe '.to_snake_case' do
    it 'should underscore-ize strings' do
      expect('FooBarBaz'.to_snake_case).to eq 'foo_bar_baz'
      expect('Foo Bar Baz'.to_snake_case).to eq 'foo_bar_baz'
      expect('foo bar baz'.to_snake_case).to eq 'foo_bar_baz'
      expect('foo bar/baz'.to_snake_case).to eq 'foo_bar_baz'
    end
  end

  describe '.to_dash_case' do
    it 'should dasher-ize strings' do
      expect('FooBarBaz'.to_dash_case).to eq 'foo-bar-baz'
      expect('Foo Bar Baz'.to_dash_case).to eq 'foo-bar-baz'
      expect('foo bar baz'.to_dash_case).to eq 'foo-bar-baz'
      expect('foo bar/baz'.to_dash_case).to eq 'foo-bar-baz'
    end
  end

end