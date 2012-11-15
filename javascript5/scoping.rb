require_relative "../common/typing"
require_relative "../common/type_parser"

module Catasta::Javascript5
  class Scope
    def initialize
      @values = {}
      @type_parser = Catasta::TypeParser.new
      @resolve_counter = Hash.new(0)
    end
    def []=(value, type)
      @values[value] = case type
      when String
        @type_parser.parse(type)
      when Catasta::Type
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
      @resolve_counter[v] += 1
      if v =~ /\A[a-zA-Z]+\w*\z/ # This is oversimplified, but good enough I think
        %{params.#{v}}
      else
        %{params["#{v}"]}
      end
    end
  end

  class LocalScope < Scope
    def resolve(v)
      @resolve_counter[v] += 1
      v.to_s
    end
  end
end