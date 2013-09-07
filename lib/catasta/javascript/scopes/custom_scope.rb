require_relative "scope"

module Catasta::JavaScript
class CustomScope < Scope
  def initialize(&block)
    super()
    @block = block
  end

  def resolve(v)
    @resolve_counter[v] += 1
    @block.call(v)
  end
end
end
