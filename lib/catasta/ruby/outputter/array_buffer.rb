module Catasta::Ruby
  class ArrayBuffer
    def preamble
      "_buffer = []"
    end
    def print(str)
      "_buffer << #{str}"
    end
    def postamble
      "return _buffer.join"
    end
  end
end
