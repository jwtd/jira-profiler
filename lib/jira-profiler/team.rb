module JiraProfiler

  class Team
    include Logger

    def initialize(name)
      @name = name
    end

    # Class level metho
    def self.standardize(v)
      return 'Zack Nelson' if v == 'Zachary Nelson'
      return 'Ray Gonzales' if v == 'Raymond Gonzales'
      return v
    end

  end

  # Record of when people were on vacation
  def vacation_log(log_filepath)
    @vacation_log = {}
    data = CSV.read(log_filepath, { encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all})
    data.each do |r|
      d = Date.new(r[:year], r[:month], r[:day])
      k = d.strftime('%Y.%m.%d')
      @vacation_log[r[:who]] = {} unless @vaction_log.has_key?(r[:who])
      @vacation_log[k] = [] unless @vaction_log.has_key?(k)
      @vacation_log[k] << r[:who]
    end

    @vacation_log
  end

  # Record of when people started and left
  def employment_log(log_filepath)
    @employment_ref = {}
    data = CSV.read(log_filepath, { encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all})
    data.each do |r|
      @employment_ref[r[:who]] = {
          :started => r[:started],
          :stopped => r[:stopped],
          :range   => (r[:started]..r[:stopped]) # Allows the use of the === comparison
      } unless @employment_ref.has_key?(r[:who])
    end
  end

end