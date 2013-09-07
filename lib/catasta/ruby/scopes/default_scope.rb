require_relative "scope"

module Catasta::Ruby
class DefaultScope < Scope
  def in_scope?(v)
    true
  end
  def resolve(v)
    @resolve_counter[v] += 1
    %{_params[:#{v}]}
  end
end
end
