require_relative "../common/typing"
require_relative "../common/type_parser"
require_relative "type_renderer"

module CurlyCurly::Java15
  class Scope
    def initialize
      @values = {}
      @type_parser = CurlyCurly::TypeParser.new
      @type_renderer = TypeRenderer.new
      @resolve_counter = Hash.new(0)
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
    def get_resolve_count(v)
      @resolve_counter[v]
    end
  end

  class ArgumentScope < Scope
    def resolve(v)
      cast = "(" + @type_renderer.simple_name(@values[v]) + ")"
      @resolve_counter[v] += 1
      %{_params.get("#{v}")}
    end
  end

  class LocalScope < Scope
    def resolve(v)
      cast = "(" + @type_renderer.simple_name(@values[v]) + ")"
      @resolve_counter[v] += 1
      v
    end
  end
end
