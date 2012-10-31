require_relative "../common/typing"
require_relative "../common/type_parser"
require_relative "type_renderer"

module CurlyCurly::Ruby
  class Scope
    def initialize
      @values = {}
      @type_parser = CurlyCurly::TypeParser.new
      @type_renderer = TypeRenderer.new
    end
    def []=(value, type)
      @values[value] = case type
      when String
        @type_parser.parse(type)
      when CurlyCurly::Type
        type
      else
        raise "Unexpected assignment: #{value} and #{type.inspect}"
      end
        
    end
    def in_scope?(v)
      @values.has_key? v
    end
    def get_type(v)
      @values[v]
    end
    def resolve(v)
      raise
    end
  end

  class ArgumentScope < Scope
    def resolve(v)
      %{params["#{v}"]} + @type_renderer.postfix(@values[v])
    end
  end

  class LocalScope < Scope
    def resolve(v)
      v.to_s + @type_renderer.postfix(@values[v])
    end
  end
end
