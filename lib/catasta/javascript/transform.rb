require "parslet"

Dir[File.join(File.dirname(__FILE__), "nodes", "**", "*.rb")].each {|f| require_relative f}

module Catasta::JavaScript
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
      javascript: simple(:javascript) 
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
    condition: {
      variable: {
        ident: simple(:variable),
      },
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