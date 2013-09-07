module Catasta::Ruby
class TemplateInclude < Struct.new(:partial_name)
  def render(ctx)
  	result = ctx.render_file(partial_name)
  	raise unless result
    result
  end
end
end
