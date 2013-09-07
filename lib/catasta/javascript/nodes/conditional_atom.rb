module Catasta::JavaScript
class ConditionalAtom < Struct.new(:inverted, :variable)
  def render(ctx)
    rendered_variable = variable.render(ctx)

    condition = inverted ? get_inverted_condition(rendered_variable) : get_condition(rendered_variable)
    # condition = ["(", condition.map {|i| "(#{i})"}.join(" || "), ")"].join("")

    condition
  end

  private
  def get_condition(rendered_variable)
    "_truthy(#{rendered_variable})"
    # [
    #   rendered_variable + " === true", # Booleans
    #   %Q{typeof #{rendered_variable} === "string" && #{rendered_variable} !== ""}, # Strings
    #   %Q{typeof #{rendered_variable} === "number" && #{rendered_variable} !== 0}, # Numbers
    #   %Q{typeof #{rendered_variable} === "object" && Object.keys(#{rendered_variable}).length > 0} # Objects and arrays
    # ]
  end

  def get_inverted_condition(rendered_variable)
    "_falsey(#{rendered_variable})"
    # [
    #   rendered_variable + " === null", # Nil
    #   rendered_variable + " === false", # Booleans
    #   rendered_variable + %q{ === ""}, # Strings
    #   %Q{#{rendered_variable} === 0}, # Numbers
    #   %Q{typeof #{rendered_variable} === "object" && Object.keys(#{rendered_variable}).length === 0} # Objects and arrays
    # ]
  end
end
end
