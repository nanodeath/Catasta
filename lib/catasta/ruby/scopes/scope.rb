module Catasta::Ruby
class Scope
  def initialize
    @values = {}
    @resolve_counter = Hash.new(0)
  end
  def <<(value)
    @values[value] = true
  end
  def in_scope?(v)
    @values.has_key? v
  end
  def resolve(v)
    raise
  end
  def get_resolve_count(v)
    @resolve_counter[v]
  end
end
end