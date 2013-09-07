require "parslet"

Dir[File.join(File.dirname(__FILE__), "nodes", "**", "*.rb")].each {|f| require_relative f}

module Catasta::Ruby
class Transform < Parslet::Transform
  rule(
    expression: {
      ident: simple(:ident)
    }
  ) {
    Code.new(VariableLookup.new(ident))
  }

  rule(
    expression: {
      ident: simple(:ident)
    }
  ) {
    Code.new(VariableLookup.new(ident))
  }

  rule(
    expression: {
      raw_string: simple(:string)
    }
  ) {
    Code.new(StringLiteral.new(string))
  }

  rule(
    expression: {
      int_literal: simple(:literal)
    }
  ) {
    Code.new(IntLiteral.new(literal))
  }

  rule(
    comment: {
      ruby: simple(:ruby)
    }
  ) {
    ''
  }

  rule(
    partial_name: {
      ident: simple(:partial_name)
    }
  ) {
    TemplateInclude.new(partial_name)
  }

  rule(
    loop: {
      i: {ident: simple(:i)},
      collection: {ident: simple(:collection)}
    },
    content: sequence(:nodes)
  ) {
    Loop.new(i, VariableLookup.new(collection), nodes)
  }

  rule(
    loop_map: {
      loop_key: {ident: simple(:loop_key)},
      loop_value: {ident: simple(:loop_value)},
      collection: {ident: simple(:collection)}
    },
    content: sequence(:nodes)
  ) {
    LoopMap.new(loop_key, loop_value, VariableLookup.new(collection), nodes)
  }

  rule(
    atomic_condition: simple(:expression)
  ) {
    AtomicExpression.new(expression)
  }

  rule(
    or: {
      left: simple(:left),
      right: simple(:right)
    }
  ) {
    OrExpression.new(left, right)
  }

  rule(
    and: {
      left: simple(:left),
      right: simple(:right)
    }
  ) {
    AndExpression.new(left, right)
  }

  # Conditional
  rule(
    condition: simple(:condition),
    content: sequence(:nodes)
  ) {
    ConditionalExpression.new(condition, nodes, [], nil)
  }

  rule(
    condition: simple(:condition),
    content: sequence(:nodes),
    elsif: sequence(:elsif_nodes),
    else: subtree(:else_content)
  ) {
    ConditionalExpression.new(condition, nodes, elsif_nodes, else_content)
  }

  # First conditional atom
  rule(
      variable: {
          ident: simple(:variable)
        },
      inverted: simple(:inverted)
  ) {
    ConditionalAtom.new(inverted, VariableLookup.new(variable), nil)
  }

  rule(
    text: simple(:text)
  ) {
    Text.new(text)
  }
  rule(
    text: sequence(:texts)
  ) {
    TextList.new(texts)
  }
  rule(
    content: sequence(:nodes)
  ) {
    Content.new(nodes)
  }
  rule(
    root: subtree(:nodes)
  ) {
    Root.new(nodes)
  }
end
end
