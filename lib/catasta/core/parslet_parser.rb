require 'parslet'
require 'pp'
require 'benchmark'

class CatastaParser < Parslet::Parser
  START_TOKEN = "{{"
  END_TOKEN = "}}"

  rule(:space)  { match('\s').repeat(1) }
  rule(:space?) { space.maybe }
  rule(:newline) { match('\n').repeat(1) }
  rule(:newline?) { newline.maybe }
  rule(:inverse) { match('!') }

  rule(:ruby) { (str(END_TOKEN).absent? >> any).repeat.as(:ruby) }
  rule(:expression) { (str('=') >> ruby).as(:expression) }
  rule(:comment) { (str('#') >> ruby) }
  rule(:loop_list) { 
    (
      str(START_TOKEN) >>
      str('for') >> 
      space >> 
      match("[a-zA-Z]").repeat(1).as(:i) >> 
      space >> 
      str('in') >> 
      space >> 
      match("[a-zA-Z]").repeat(1).as(:collection) >>
      str(END_TOKEN) >>
      newline?
    ).as(:loop) >> 
    text_with_ruby >> 
    str(START_TOKEN) >>
    str('/for') >>
    str(END_TOKEN) >>
    newline?
  }
  rule(:loop_map) {
    (
      str(START_TOKEN) >>
      str('for') >> 
      space >> 
      match("[a-zA-Z]").repeat(1).as(:loop_key) >>
      match(",") >>
      space? >>
      match("[a-zA-Z]").repeat(1).as(:loop_value) >>
      space >>
      str('in') >> 
      space >> 
      match("[a-zA-Z]").repeat(1).as(:collection) >>
      str(END_TOKEN) >>
      newline?
    ).as(:loop_map) >> 
    text_with_ruby >> 
    str(START_TOKEN) >>
    str('/for') >>
    str(END_TOKEN) >>
    newline?
  }
  rule(:iff) {
    (
      str(START_TOKEN) >>
      str('if') >>
      space >>
      inverse.maybe.as(:inverted) >>
      match("[a-zA-Z]").repeat(1).as(:variable) >>
      str(END_TOKEN) >>
      newline?
    ).as(:condition) >>
    text_with_ruby >>
    str(START_TOKEN) >>
    str('/if') >>
    str(END_TOKEN) >>
    newline?
  }
  rule(:catasta) { expression | comment}

  rule(:catasta_with_matching_tags) { loop_list | loop_map | iff }

  rule(:catasta_with_tags) { str(START_TOKEN) >> catasta >> str(END_TOKEN) >> newline? }
  
  rule(:text) { (str(START_TOKEN).absent? >> any).repeat(1).as(:text) }
  
  rule(:text_with_ruby) { (text | catasta_with_matching_tags | catasta_with_tags).repeat.as(:content) }
  rule(:root_text_with_ruby) { text_with_ruby.as(:root) }
  root(:root_text_with_ruby)
end

# p CatastaParser.new.parse("Hello world!")
for_loop = CatastaParser.new.parse("Hello {{for c in foo}}monkey!{{=c}}{{/for}}")
# pp for_loop
# puts("Parse: " + (Benchmark.measure { CatastaParser.new.parse("Hello {{for c in foo}}monkey!{{=c}}{{/for}}") }))
# p CatastaParser.new.parse("Hello {{= name}}! {{#a friendly greeting}}")

class Scope
  def initialize
    @values = {}
  end
  def []=(value, type)
    @values[value] = true
  end
  def in_scope?(v)
    @values.has_key? v
  end
  def resolve(v)
    raise
  end
end

class DefaultScope < Scope
  def in_scope?(v)
    true
  end
  def resolve(v)
    %{_params[:#{v.strip}]}
  end
end

class LocalScope < Scope
  def resolve(v)
    v.to_s
  end
end

class Context
  attr_reader :scopes
  def initialize
    @scopes = []
    @indent = 0
  end
  def add_scope(scope)
    @scopes.unshift scope
    if block_given?
      body = yield
      pop_scope
      body
    end
  end
  def pop_scope
    @scopes.shift
  end
  def indent
    @indent += 1
    if block_given?
      body = yield
      unindent
      body
    end
  end
  def unindent
    @indent -= 1
  end
  def pad(str)
    " " * @indent * 2 + str
  end
end

class VariableLookup < Struct.new(:var)
  def render(ctx)
    var_name = var.str.to_s
    scope = ctx.scopes.find {|s| s.in_scope? var_name}
    raise "Couldn't resolve #{var_name}" unless scope
    scope.resolve(var_name)
  end
end
class Code < Struct.new(:code)
  def render(ctx)
    result = code.respond_to?(:render) ? code.render(ctx) : code.str
    ctx.pad %Q{puts #{result}}
  end
end
class Text < Struct.new(:text)
  def render(ctx)
    textz = text.str.gsub(/\n/, '\n')
    ctx.pad %Q{puts "#{textz}"}
  end
end
class TextList < Struct.new(:texts)
  def render(ctx)
    texts.map {|t| t.render(ctx)}.join("\n")
  end
end
class Loop < Struct.new(:loop_var, :collection, :nodes)
  def render(ctx)
    s = LocalScope.new
    s[loop_var.str] = "cat"
    inner = ctx.add_scope(s) do
      ctx.indent { nodes.map {|n| n.render(ctx)}.join("\n") }
    end
    ctx.pad %Q{#{collection.render(ctx)}.each do |#{loop_var}|\n} + inner + "\nend\n"
  end
end
class LoopMap < Struct.new(:loop_key, :loop_value, :collection, :nodes)
  def render(ctx)
    s = LocalScope.new
    s[loop_key.str] = "cat"
    s[loop_value.str] = "f"
    inner = ctx.add_scope(s) do
      ctx.indent { nodes.map {|n| n.render(ctx)}.join("\n") }
    end
    ctx.pad %Q{#{collection.render(ctx)}.each_pair do |#{loop_key}, #{loop_value}|\n} + inner + "\nend\n"
  end
end
class Content < Struct.new(:nodes)
  def render(ctx)
    nodes.map {|n| n.render(ctx)}.join("\n") + "\n"
  end
end
class Conditional < Struct.new(:inverted, :variable, :nodes)
  def render(ctx)
    rendered_variable = variable.render(ctx)
    condition = inverted ? get_inverted_condition(rendered_variable) : get_condition(rendered_variable)
    condition = condition.map {|i| "(#{i})"}.join(" || ")
    inner = ctx.indent { nodes.map {|n| n.render(ctx)} }
    ["if(#{condition})", inner, "end"].flatten.join("\n")
  end

  private
  def get_condition(rendered_variable)
    [
      rendered_variable + ".is_a?(TrueClass)", # Booleans
      rendered_variable + ".is_a?(String) && " + rendered_variable + %q{ != ""}, # Strings
      rendered_variable + ".respond_to?(:empty?) && !#{rendered_variable}.empty?", # Hashes and Arrays
    ]
  end

  def get_inverted_condition(rendered_variable)
    [
      rendered_variable + ".nil?", # Nil
      rendered_variable + ".is_a?(FalseClass)", # Booleans
      rendered_variable + %q{ == ""}, # Strings
      rendered_variable + ".respond_to?(:empty?) && #{rendered_variable}.empty?", # Hashes and Arrays
    ]
  end
end
class Root < Struct.new(:nodes)
  def generate(options={})
    ctx = Context.new
    scope = DefaultScope.new
    ctx.add_scope scope
    nodes.render(ctx)
    # puts nodes.inspect
    # nodes.map {|n| puts "calling render on #{n.inspect}"; n.render(ctx)}.join("\n") + "\n"
  end
end

class CatastaRubyTransform < Parslet::Transform
  rule(:expression => { :ruby => simple(:ruby) }) { Code.new(VariableLookup.new(ruby)) }
  rule(:comment => { :ruby => simple(:ruby) }) { '' }
  rule(:loop => { :i => simple(:i), :collection => simple(:collection) }, :content => sequence(:nodes)) { Loop.new(i, VariableLookup.new(collection), nodes) }
  rule(:loop_map => { :loop_key => simple(:loop_key), :loop_value => simple(:loop_value), :collection => simple(:collection) }, :content => sequence(:nodes)) {
    LoopMap.new(loop_key, loop_value, VariableLookup.new(collection), nodes)
  }
  rule(:condition => { :variable => simple(:variable), :inverted => simple(:inverted) }, :content => sequence(:nodes)) { Conditional.new(inverted, VariableLookup.new(variable), nodes) }
  
  rule(:text => simple(:text)) { Text.new(text) }
  rule(:text => sequence(:texts)) { TextList.new(texts) }
  rule(:content => sequence(:nodes)) { Content.new(nodes) }
  rule(:root => subtree(:nodes)) { Root.new(nodes) }
end

# puts "\n\nTransforms:\n"

# puts CatastaRubyTransform.new.apply(for_loop).generate
# puts("Transform: " + Benchmark.measure { CatastaRubyTransform.new.apply(for_loop).generate })
# Hello {{= name }}!
# FILE