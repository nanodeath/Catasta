require "parslet"

Dir[File.join(File.dirname(__FILE__), "nodes", "**", "*.rb")].each {|f| require_relative f}

module Catasta::Ruby
class Transform < Parslet::Transform
  rule(
    expression: { 
      ruby: simple(:ruby) 
    }
  ) {
    Code.new(VariableLookup.new(ruby))
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
    loop: {
      i: simple(:i),
      collection: simple(:collection)
    },
    content: sequence(:nodes)
  ) {
    Loop.new(i, VariableLookup.new(collection), nodes)
  }

  rule(
    loop_map: {
      loop_key: simple(:loop_key),
      loop_value: simple(:loop_value),
      collection: simple(:collection)
    },
    content: sequence(:nodes)
  ) {
    LoopMap.new(loop_key, loop_value, VariableLookup.new(collection), nodes)
  }
  
  rule(
    condition: {
      variable: simple(:variable),
      inverted: simple(:inverted)
    },
    content: sequence(:nodes)
  ) {
    Conditional.new(inverted, VariableLookup.new(variable), nodes)
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
