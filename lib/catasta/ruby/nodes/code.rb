module Catasta::Ruby
class Code < Struct.new(:code)
  def render(ctx)
    result = code.respond_to?(:render) ? code.render(ctx) : code.str
    ctx.write result
  end
end
end
