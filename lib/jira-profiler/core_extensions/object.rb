module CoreExtensions
  module Object

    def deep_symbolize_keys
      return self.inject({}){|memo,(k,v)| memo[k.to_sym] = v.deep_symbolize_keys; memo} if self.is_a? Hash
      return self.inject([]){|memo,v    | memo           << v.deep_symbolize_keys; memo} if self.is_a? Array
      return self
    end

  end
end