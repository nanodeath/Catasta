

module Test
  class Test1
    def self.template(_params)
      _buf = []
      _buf << "This is just a static template -- just plain text."
      _buf.join
    end

  end
end
