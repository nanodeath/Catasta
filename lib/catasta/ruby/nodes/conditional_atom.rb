module Catasta::Ruby
class ConditionalAtom < Struct.new(:inverted, :variable, :operator)
  def render(ctx)
    rendered_variable = variable.render(ctx)

    condition = inverted ? get_inverted_condition(rendered_variable) : get_condition(rendered_variable)
    if operator == "and"
      condition = " && #{condition}"
    elsif operator == "or"
      condition = " || #{condition}"
    end

    condition
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
