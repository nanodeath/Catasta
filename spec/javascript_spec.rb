require_relative "spec_helper"
require "catasta/javascript/outputter/array_buffer"
require 'rspec/expectations'

class BareArrayOutputter
  def preamble
    nil
  end
  def print(str)
    "_arr.push(#{str});"
  end
  def postamble
    nil
  end
end

describe Catasta::JavaScript do
  matcher :compile_to do |expected|
    match do |actual|
      parsed = Catasta::Parser.new.parse(actual)
      result = begin
        transform = Catasta::JavaScript::Transform.new
        transform.apply(parsed).generate(outputter: BareArrayOutputter.new, path: File.dirname(__FILE__), transform: transform)
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
_arr.push("Hello world!\\n");
OUTPUT
    end

    it "should process evaluation of variables" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello {{= name}}!
INPUT
_arr.push("Hello ");
_arr.push(_params['name']);
_arr.push("!\\n");
OUTPUT
    end
    it "should process nested variables" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello {{= person.name}}!
The weather is {{= weather.today.seattle}}.
INPUT
_arr.push("Hello ");
_arr.push(['name'].reduce(function(memo, field){
  if(memo){
    return memo[field];
  } else {
    return "";
  }
}, _params['person']));
_arr.push("!\\nThe weather is ");
_arr.push(['today','seattle'].reduce(function(memo, field){
  if(memo){
    return memo[field];
  } else {
    return "";
  }
}, _params['weather']));
_arr.push(".\\n");
OUTPUT
    end

    it "should process evaluation of strings" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello {{= "Bob"}}!
INPUT
_arr.push("Hello ");
_arr.push("Bob");
_arr.push("!\\n");
OUTPUT
    end
=begin

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
      <<INPUT.should compile_to(<<OUTPUT)
{{if monkey}}
  Monkey is truthy.
{{/if}}
INPUT
if((_params[:monkey].is_a?(TrueClass)) || (_params[:monkey].is_a?(String) && _params[:monkey] != "") || (_params[:monkey].respond_to?(:empty?) && !_params[:monkey].empty?))
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
if((_params[:monkey].nil?) || (_params[:monkey].is_a?(FalseClass)) || (_params[:monkey] == "") || (_params[:monkey].respond_to?(:empty?) && _params[:monkey].empty?))
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
=end
  end
end