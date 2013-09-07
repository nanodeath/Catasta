module Catasta::Ruby
class Text < Struct.new(:text)
  def render(ctx)
    textz = text.str.gsub(/\n/, '\n')
    ctx.write %Q{"#{textz}"}
  end
end
end
