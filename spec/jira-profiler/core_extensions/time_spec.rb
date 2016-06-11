require 'spec_helper'

describe CoreExtensions::Time do


  describe '.years_from' do
    it 'should calculate the years from the provided date' do
      t1 = Time.new(2013,1,1)
      t2 = Time.new(2014,1,1)
      expect(t1.years_from(t2)).to eq 1
    end
  end

  describe '.months_from' do
    it 'should calculate the months from the provided date' do
      t1 = Time.new(2014,1,1)
      t2 = Time.new(2014,2,1)
      expect(t1.years_from(t2)).to eq 1
    end
  end

  describe '.weeks_from' do
    it 'should calculate the weeks from the provided date' do
      expect(Time.now().weeks_from(Time.now())).to eq 0
    end
  end

  describe '.days_from' do
    it 'should calculate the days from the provided date' do
      t1 = Time.new(2014,1,1)
      t2 = Time.new(2014,1,2)
      expect(Time.now().days_from(Time.now())).to eq 0
      expect(t1.days_from(t2)).to eq 1
    end
  end

  describe '.hours_from' do
    it 'should calculate the hours from the provided date' do
      expect(Time.now().hours_from(Time.now())).to eq 0
    end
  end

  describe '.minutes_from' do
    it 'should calculate the minutes from the provided date' do
      expect(Time.now().minutes_from(Time.now())).to eq 0
    end
  end

  describe '.seconds_from' do
    it 'should calculate the seconds from the provided date' do
      expect(Time.now().seconds_from(Time.now())).to eq 0
    end
  end


  describe '.as_sortable_timestamp' do
    it 'should print the date as sortable string' do
      expect(Time.now().as_sortable_timestamp).to eq '%-m/%-d/%Y %H:%M'
    end
  end

  describe '.time_from' do
    it 'should print out the elapsed time in human readable text' do
      expect(Time.now().time_from(Time.now())).to eq 0
    end
  end

  describe '.time_components_from' do
    it 'should return a hash containing the time components' do
      expect(Time.now().time_components_from(Time.now())).to eq 0
    end
  end

end