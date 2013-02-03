module Catasta::Ruby
class Conditional < Struct.new(:inverted, :variable, :nodes)
  def render(ctx)
    rendered_variable = variable.render(ctx)
    
    if inverted
      condition = get_inverted_condition(rendered_variable)
    else
      condition = get_condition(rendered_variable)
    end
    inner = ctx.indent { nodes.map {|n| n.render(ctx)} }
    [ctx.pad("if(#{condition})"), inner, ctx.pad("end")].flatten.join("\n")
  end

  private
  def get_condition(rendered_variable)
    "Catasta::Conditional.truthy(#{rendered_variable})"
    # [
    #   rendered_variable + ".is_a?(TrueClass)", # Booleans
    #   rendered_variable + ".is_a?(String) && " + rendered_variable + %q{ != ""}, # Strings
    #   rendered_variable + ".respond_to?(:empty?) && !#{rendered_variable}.empty?", # Hashes and Arrays
    # ]
  end

  def get_inverted_condition(rendered_variable)
    "Catasta::Conditional.falsey(#{rendered_variable})"
    # [
    #   rendered_variable + ".nil?", # Nil
    #   rendered_variable + ".is_a?(FalseClass)", # Booleans
    #   rendered_variable + %q{ == ""}, # Strings
    #   rendered_variable + ".respond_to?(:empty?) && #{rendered_variable}.empty?", # Hashes and Arrays
    # ]
  end
end
end
