module Catasta::JavaScript
  class ArrayBuffer
    def preamble
      "var _arr = [];"
    end
    def print(str)
      "_arr.push(#{str});"
    end
    def postamble
      "return _arr.join();"
    end
  end
end
