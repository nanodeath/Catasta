require_relative "spec_helper"
require 'rspec/expectations'

class PutsOutputter
  def preamble
    nil
  end
  def print(str)
    "puts #{str}"
  end
  def postamble
    nil
  end
end


describe Catasta::Ruby do
  matcher :compile_to do |expected|
    match do |actual|
      begin
        parsed = Catasta::Parser.new.parse(actual)
      rescue StandardError => e
        puts e.cause.ascii_tree
        raise e
      end
      result = begin
        transform = Catasta::Ruby::Transform.new
        transform.apply(parsed).generate(outputter: PutsOutputter.new, path: File.dirname(__FILE__), transform: transform)
      rescue
        puts "Failed while transforming"
        pp parsed
        raise
      end
      @result = result
      if result != expected
        pp parsed
      end
      result == expected
    end

    failure_message_for_should do |actual|
      "expected:\n#{expected}, got:\n#@result"
    end
  end

  describe :basics do
    it "should process static text" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello world!
INPUT
puts "Hello world!\\n"
OUTPUT
    end

    it "should process evaluation of variables" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello {{= name}}!
INPUT
puts "Hello "
puts _params[:name]
puts "!\\n"
OUTPUT
    end

    it "should process nested variables" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello {{= person.name}}!
The weather is {{= weather.today.seattle}}.
INPUT
puts "Hello "
puts [:name].inject(_params[:person]) do |memo, val|
  if memo != ""
    memo = if memo.respond_to?(val)
      memo.send(val)
    elsif memo.respond_to?(:[])
      memo[val]
    else
      ""
    end
  end
  memo
end
puts "!\\nThe weather is "
puts [:today,:seattle].inject(_params[:weather]) do |memo, val|
  if memo != ""
    memo = if memo.respond_to?(val)
      memo.send(val)
    elsif memo.respond_to?(:[])
      memo[val]
    else
      ""
    end
  end
  memo
end
puts ".\\n"
OUTPUT
    end

    it "should process evaluation of strings" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello {{= "Bob"}}!
INPUT
puts "Hello "
puts "Bob"
puts "!\\n"
OUTPUT
    end

    it "should process evaluation of integers" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello, it is {{= 1}} o'clock!  '
INPUT
puts "Hello, it is "
puts 1
puts " o'clock!  '\\n"
OUTPUT
    end

    it "should process loops over arrays" do
      <<INPUT.should compile_to(<<OUTPUT)
<ol>
{{for c in content}}
  <li>{{=c}}</li>
{{/for}}
</ol>
INPUT
puts "<ol>\\n"
_params[:content].each do |c|
  puts "  <li>"
  puts c
  puts "</li>\\n"
end
puts "</ol>\\n"
OUTPUT
    end

    it "should process loops over arrays with indexes" do
      <<INPUT.should compile_to(<<OUTPUT)
<ol>
{{for c in content}}
  <li>{{= @c}}: {{=c}}</li>
{{/for}}
</ol>
INPUT
puts "<ol>\\n"
_params[:content].each_with_index do |c, _c_index|
  puts "  <li>"
  puts _c_index
  puts ": "
  puts c
  puts "</li>\\n"
end
puts "</ol>\\n"
OUTPUT
    end

    it "should process basic conditionals" do
      # (_params[:monkey].is_a?(TrueClass)) || (_params[:monkey].is_a?(String) && _params[:monkey] != "") || (_params[:monkey].respond_to?(:empty?) && !_params[:monkey].empty?)
      <<INPUT.should compile_to(<<OUTPUT)
{{if monkey}}
  Monkey is truthy.
{{/if}}
INPUT
if(Catasta::Conditional.truthy(_params[:monkey]))
  puts "  Monkey is truthy.\\n"
end
OUTPUT
    end

    it "should process basic inverse conditionals" do
      <<INPUT.should compile_to(<<OUTPUT)
{{if !monkey}}
  Monkey is falsey.
{{/if}}
INPUT
if(Catasta::Conditional.falsey(_params[:monkey]))
  puts "  Monkey is falsey.\\n"
end
OUTPUT
    end

    it "should process loops over maps" do
      <<INPUT.should compile_to(<<OUTPUT)
<ol>
{{for k,v in content}}
  <li>{{=k}}: {{=v}}</li>
{{/for}}
</ol>
INPUT
puts "<ol>\\n"
_params[:content].each_pair do |k, v|
  puts "  <li>"
  puts k
  puts ": "
  puts v
  puts "</li>\\n"
end
puts "</ol>\\n"
OUTPUT
    end

    it "should parse and statements" do
      parser = Catasta::Parser.new
      parser.logical_and_expression.parse("a and !b").should == {
        and: {
          left: {
            inverted: nil,
            variable: {
              ident:"a"
              }
          }, right: {
            inverted: "!",
            variable: {
              ident: "b"
            }
          }
        }
      }
    end

    it "should process binary boolean logic" do
      <<INPUT.should compile_to(<<OUTPUT)
{{if monkey and banana}}
  Monkey and banana are truthy.
{{/if}}
{{if dog or banana}}
  Dog or banana are truthy.
{{/if}}
INPUT
if(Catasta::Conditional.truthy(_params[:monkey]) && Catasta::Conditional.truthy(_params[:banana]))
  puts "  Monkey and banana are truthy.\\n"
end
if(Catasta::Conditional.truthy(_params[:dog]) || Catasta::Conditional.truthy(_params[:banana]))
  puts "  Dog or banana are truthy.\\n"
end
OUTPUT
    end

    it "should process multiple binary boolean logic" do
      <<INPUT.should compile_to(<<OUTPUT)
{{if monkey and banana and cat}}
  Monkey and banana and cat are truthy.
{{/if}}
INPUT
if(Catasta::Conditional.truthy(_params[:monkey]) && Catasta::Conditional.truthy(_params[:banana]) && Catasta::Conditional.truthy(_params[:cat]))
  puts "  Monkey and banana and cat are truthy.\\n"
end
OUTPUT
    end

    it "should process mixed multiple binary boolean logic" do
      <<INPUT.should compile_to(<<OUTPUT)
{{if monkey or banana and cat}}
  Monkey or banana and cat are truthy.
{{/if}}
{{if monkey and banana or cat}}
  Monkey and banana or cat are truthy.
{{/if}}
INPUT
if(Catasta::Conditional.truthy(_params[:monkey]) || Catasta::Conditional.truthy(_params[:banana]) && Catasta::Conditional.truthy(_params[:cat]))
  puts "  Monkey or banana and cat are truthy.\\n"
end
if(Catasta::Conditional.truthy(_params[:monkey]) && Catasta::Conditional.truthy(_params[:banana]) || Catasta::Conditional.truthy(_params[:cat]))
  puts "  Monkey and banana or cat are truthy.\\n"
end
OUTPUT
    end

    it "should process scoped multiple binary boolean logic" do
      <<INPUT.should compile_to(<<OUTPUT)
{{if (monkey or banana) and cat}}
  (Monkey or banana) and cat are truthy.
{{/if}}
INPUT
if((Catasta::Conditional.truthy(_params[:monkey]) || Catasta::Conditional.truthy(_params[:banana])) && Catasta::Conditional.truthy(_params[:cat]))
  puts "  (Monkey or banana) and cat are truthy.\\n"
end
OUTPUT
    end

    it "should process partials" do
      <<INPUT.should compile_to(<<OUTPUT)
<div class="person">
  {{> person}}
</div>
INPUT
puts "<div class=\"person\">\\n  "
puts "Name: "
puts _params[:name]
puts "</div>\\n"
OUTPUT
    end
  end
end