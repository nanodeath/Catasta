

module Test
  class Test1
    def self.template(_params)
      _buf = []
      _buf << ""
      if params["str"].to_s != ""
        _buf << "    Hello "
        _buf << params["str"].to_s
        _buf << ""
      end
      _buf.join
    end

  end
end
