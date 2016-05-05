module CoreExtensions
  module String

    def to_bool
      return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
      return false if self == false || self.empty? || self =~ (/^(false|f|no|n|0)$/i)
      raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
    end

    def to_snake_case!
      gsub!(/(.)([A-Z])/,'\1 \2')
      gsub!(/([_ ])+/, '_')
      downcase!
    end

    def to_snake_case
      dup.tap { |s| s.to_snake_case! }
    end

    def to_dash_case!
      to_snake_case!
      gsub!('_', '-')
    end

    def to_dash_case
      dup.tap { |s| s.to_dash_case! }
    end

  end
end