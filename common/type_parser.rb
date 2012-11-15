# Parses the types listed in the front matter of templates
module Catasta
  class TypeParser
    def parse(type)
      case type
      when "int"
        Integer.new
      when "float"
        Float.new
      when "str"
        String.new
      when "obj"
        Object.new
      when /list of (\w+)/
        List.new(parse($~[1]))
      when /map of (\w+):(\w+)/
        Map.new(parse($~[1]), parse($~[2]))
      else
        raise "Unexpected type `#{type}`"
      end
    end
  end
end

