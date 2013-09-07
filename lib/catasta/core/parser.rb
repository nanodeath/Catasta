require "parslet"

module Catasta
class Parser < Parslet::Parser
  START_TOKEN = "{{"
  END_TOKEN = "}}"

  def simple_tag(text)
    tag(str(text))
  end

  def tag(nodes)
    str(START_TOKEN) >> nodes >> str(END_TOKEN) >> newline?
  end

  def single_ident
    match("[a-zA-Z]") >> match("[a-zA-Z0-9_]").repeat
  end

  def ident
    (str("@").maybe >> single_ident >> (str('.') >> single_ident).repeat).as(:ident)
  end

  rule(:space)  { str("\s").repeat(1) }
  rule(:space?) { space.maybe }
  rule(:newline) { match('\n').repeat(1) }
  rule(:newline?) { newline.maybe }
  rule(:inverse) { match('!') }

  rule(:string) { str('"') >> (str('"').absent? >> any).repeat.as(:raw_string) >> str('"') }
  rule(:integer) { match('[0-9]').repeat(1).as(:int_literal) }
  rule(:ruby) { (str(END_TOKEN).absent? >> any).repeat.as(:ruby) }

  # Unary Commands
  rule(:partial) { str('>') >> space? >> ident.as(:partial_name) }
  rule(:simple_expression) { string | integer | ident | ruby }
  rule(:expression) { str('=') >> space? >> simple_expression.as(:expression) }
  rule(:comment) { (str('#') >> ruby) }

  # Block Commands
  rule(:loop_list) {
    tag(
      str('for') >> space >> ident.as(:i) >> space >> str('in') >> space >> ident.as(:collection)
    ).as(:loop) >>
    text_with_ruby >>
    simple_tag('/for') >>
    newline?
  }
  rule(:loop_map) {
    tag(
      str('for') >> space >> ident.as(:loop_key) >> match(",") >> space? >> ident.as(:loop_value) >> space >> str('in') >> space >> ident.as(:collection)
    ).as(:loop_map) >>
    text_with_ruby >>
    simple_tag('/for') >>
    newline?
  }
  rule(:primary) {
    (str("(") >> logical_or_expression >> str(")")).as(:atomic_condition) |
    (inverse.maybe.as(:inverted) >> simple_expression.as(:variable))
  }
  # rule(:inverse_expression) {
  #   inverse.maybe.as(:inverted) >>
  #   simple_expression.as(:variable)
  # }
  # rule(:comparator) { str('>') | str('>=') | str('<') | str('<=') | str('==') | str('!=') }
  rule(:logical_and_expression) {
    (primary.as(:left) >> space >> str('and') >> space >> logical_and_expression.as(:right)).as(:and) | primary
    # inverse_expression >> space >> str('and') >> space >> inverse_expression
  }
  rule(:logical_or_expression) {
    (logical_and_expression.as(:left) >> space >> str('or') >> space >> logical_or_expression.as(:right)).as(:or) | logical_and_expression
    # logical_and_expression | (logical_or_expression.as(:expression) >> space >> str('or') >> space >> logical_and_expression)
    #condition.as(:condition_atom) >> (space? >> conditional_operator.as(:operator) >> space? >> condition.as(:condition_atom)).repeat
    # |
    # (str('(').as(:wrapped) >> space? >> compound_condition >> space? >> str(')'))
  }
  # rule(:condition) {
  #     inverse.maybe.as(:inverted) >> simple_expression.as(:variable) #>> (space >> comparator.as(:comparator) >> space >> simple_expression.as(:variable2)).maybe# |
  #     #compound_condition#(condition >> (space >> compound_conditional >> space >> condition).repeat(1))
  # }
  rule(:iff) {
    tag(
      str('if') >>
      space >>
      logical_or_expression
      #compound_condition# | condition)
    ).as(:condition) >>
    text_with_ruby >>
    (simple_tag('else') >> text_with_ruby).maybe.as(:else) >>
    simple_tag('/if') >>
    newline?
  }
  rule(:unary_catasta) { partial | expression | comment}

  rule(:catasta_with_matching_tags) { loop_list | loop_map | iff }

  rule(:catasta_with_tags) { tag(unary_catasta) }

  rule(:text) { (str(START_TOKEN).absent? >> any).repeat(1).as(:text) }

  rule(:text_with_ruby) { (text | catasta_with_matching_tags | catasta_with_tags).repeat.as(:content) }
  rule(:root_text_with_ruby) { text_with_ruby.as(:root) }
  root(:root_text_with_ruby)
end
end