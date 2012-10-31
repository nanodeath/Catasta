

module Test
  class Test1
    def self.template(_params)
      _buf = []
      _buf << "This template has "
      _buf << params["variable"].to_s
      _buf << " content."
      _buf.join
    end

  end
end
