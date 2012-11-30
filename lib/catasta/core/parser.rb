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

  rule(:space)  { match('\s').repeat(1) }
  rule(:space?) { space.maybe }
  rule(:newline) { match('\n').repeat(1) }
  rule(:newline?) { newline.maybe }
  rule(:inverse) { match('!') }

  rule(:string) { str('"') >> (str('"').absent? >> any).repeat.as(:raw_string) >> str('"') }
  rule(:integer) { match('[0-9]').repeat(1).as(:int_literal) }
  rule(:ruby) { (str(END_TOKEN).absent? >> any).repeat.as(:ruby) }

  # Unary Commands
  rule(:partial) { str('>') >> space? >> ident.as(:partial_name) }
  rule(:expression) { (str('=') >> space? >> (string | integer | ident | ruby)).as(:expression) }
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
  rule(:iff) {
    tag(
      str('if') >>
      space >>
      inverse.maybe.as(:inverted) >>
      ident.as(:variable)
    ).as(:condition) >>
    text_with_ruby >>
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