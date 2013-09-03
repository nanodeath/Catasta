module Catasta::JavaScript
class Text < Struct.new(:text)
  def render(ctx)
    textz = text.str.gsub(/\n/, '\n')

    has_double_quotes = textz.include? '"'
    if has_double_quotes
    	has_single_quotes = textz.include? "'"
    	if has_single_quotes
			textz.gsub!(/"/, "\"")
			ctx.write %Q{"#{textz}"}
		else
		  	ctx.write %Q{'#{textz}'}
		end
	else
	    ctx.write %Q{"#{textz}"}
	end
  end
end
end
