module CurlyCurly
  module Ruby
    class TypeRenderer
      def postfix(type)
        case type
        when Integer
          ".to_i"
        when Float
          ".to_f"
        when String
          ".to_s"
        else
          ""
        end
      end
    end
  end
end
