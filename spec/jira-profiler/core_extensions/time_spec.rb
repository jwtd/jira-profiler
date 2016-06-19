require 'spec_helper'

describe CoreExtensions::Time do

  before(:all) do
    @t1 = Time.new(2013,1,1)
  end

  describe '.years_from' do
    it 'should calculate the years from the provided date' do
      t2 = Time.new(2014,1,1)
      t3 = Time.new(2015,1,1)
      expect(@t1.years_from(t2)).to eq 1
      expect(@t1.years_from(t3)).to eq 2.0
    end
  end

  describe '.months_from' do
    it 'should calculate the months from the provided date' do
      t2 = Time.new(2013,3,1)
      t3 = Time.new(2014,3,1)
      expect(@t1.months_from(t2)).to eq 1.94
      expect(@t1.months_from(t3)).to eq 13.94
    end
  end

  describe '.weeks_from' do
    it 'should calculate the weeks from the provided date' do
      t2 = Time.new(2013,1,7)
      t3 = Time.new(2014,1,7)
      expect(@t1.weeks_from(t2)).to eq 0.86
      expect(@t1.weeks_from(t3)).to eq 53
    end
  end

  describe '.days_from' do
    it 'should calculate the days from the provided date' do
      t2 = Time.new(2013,1,7)
      t3 = Time.new(2014,1,7)
      expect(@t1.days_from(t2)).to eq 6
      expect(@t1.days_from(t3)).to eq 371.0
    end
  end

  describe '.hours_from' do
    it 'should calculate the hours from the provided date' do
      t2 = Time.new(2013,1,2)
      t3 = Time.new(2013,1,1,12)
      expect(@t1.days_from(t2)).to eq 1.0
      expect(@t1.days_from(t3)).to eq 0.5
    end
  end

  describe '.minutes_from' do
    it 'should calculate the minutes from the provided date' do
      t2 = Time.new(2013,1,1,1)
      t3 = Time.new(2013,1,1,3, 31)
      expect(@t1.minutes_from(t2)).to eq 60
      expect(@t1.minutes_from(t3)).to eq 211.0
    end
  end

  describe '.seconds_from' do
    it 'should calculate the seconds from the provided date' do
      t2 = Time.new(2013,1,1,0, 5)
      t3 = Time.new(2013,1,1,1, 7)
      expect(@t1.seconds_from(t2)).to eq 300
      expect(@t1.seconds_from(t3)).to eq 4020
    end
  end

  describe '.weekend?' do
    it 'should return boolean indicating if its a weekend or not' do
      t2 = Time.new(2016,6,19)
      t3 = Time.new(2016,6,20)
      expect(t2.weekend?).to eq true
      expect(t3.weekend?).to eq false
    end
  end

  describe '.weekday?' do
    it 'should return boolean indicating if its a weekday or not' do
      t2 = Time.new(2016,6,19)
      t3 = Time.new(2016,6,20)
      expect(t2.weekday?).to eq false
      expect(t3.weekday?).to eq true
    end
  end

  describe '.as_sortable_timestamp' do
    it 'should print the date as sortable string' do
      expect(@t1.as_sortable_timestamp).to eq '2013.01.01.00.00.1357016400' # %Y.%m.%d.%H.%M.%s
    end
  end

  describe '.as_sortable_datetime' do
    it 'should print the date as sortable string' do
      expect(@t1.as_sortable_datetime).to eq '2013.01.01.00.00' # %Y.%m.%d.%H.%M
    end
  end

  describe '.as_sortable_date' do
    it 'should print the date as sortable string' do
      expect(@t1.as_sortable_date).to eq '2013.01.01' # %Y.%m.%d
    end
  end

  # describe '.time_from' do
  #   it 'should print out the elapsed time in human readable text' do
  #     t2 = Time.new(2013,1,1,0, 5)
  #     t3 = Time.new(2013,1,1,1, 7)
  #     expect(@t1.time_from(t2)).to eq '5 seconds'
  #     expect(@t1.time_from(t3)).to eq '1 hour 7 seconds'
  #   end
  # end

  describe '.time_components_from' do
    it 'should return a hash containing the time components' do
      t2 = Time.new(2014,2,2,1,2)
      result = @t1.time_components_from(t2)
      expect(result[:years]).to eq 1.09
      expect(result[:months]).to eq 13.05
      expect(result[:weeks]).to eq 56.72
      expect(result[:days]).to eq 397.04
      expect(result[:hours]).to eq 9529.03
      expect(result[:minutes]).to eq 571742.0
      expect(result[:seconds]).to eq 34304520.0
    end
  end

end