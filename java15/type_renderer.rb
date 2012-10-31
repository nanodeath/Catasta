module CurlyCurly
  module Java15
    class TypeRenderer
      def simple_name(type)
        case type
        when Integer
          "Integer"
        when Float
          "Float"
        when String
          "String"
        when List
          "List" + (type.get_subtype(:value).nil? ? "" : "<#{simple_name(type.get_subtype(:value))}>")
        when Map
          key, value = [:key, :value].map do |subtype|
            type.get_subtype(subtype)
          end
          if key.nil? || value.nil?
            "Map"
          else
            "Map<#{simple_name(key)}, #{simple_name(value)}>"
          end
        else
          "Object"
        end
      end
    end
  end
end

