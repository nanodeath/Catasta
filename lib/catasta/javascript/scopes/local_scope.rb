require_relative "scope"

module Catasta::JavaScript
class LocalScope < Scope
  def resolve(v)
    @resolve_counter[v] += 1
    v.to_s
  end
end
end
