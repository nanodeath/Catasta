require_relative "spec_helper"
require "catasta/javascript/outputter/array_buffer"
require 'rspec/expectations'


describe Catasta::JavaScript do
  matcher :compile_to do |expected|
    match do |actual|
      parsed = Catasta::Parser.new.parse(actual)
      result = begin
        transform = Catasta::JavaScript::Transform.new
        transform.apply(parsed).generate(outputter: Catasta::JavaScript::ArrayBuffer.new, path: File.dirname(__FILE__), transform: transform)
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
var _arr = [];
_arr.push("Hello world!\\n");
return _arr.join();
OUTPUT
    end

    it "should process evaluation of variables" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello {{= name}}!
INPUT
var _arr = [];
_arr.push("Hello ");
_arr.push(_params['name']);
_arr.push("!\\n");
return _arr.join();
OUTPUT
    end
=begin
    it "should process nested variables" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello {{= person.name}}!
The weather is {{= weather.today.seattle}}.
INPUT
puts "Hello "
puts [:name].inject(_params[:person]) {|memo, val|
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
}
puts "!\\nThe weather is "
puts [:today,:seattle].inject(_params[:weather]) {|memo, val|
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
}
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