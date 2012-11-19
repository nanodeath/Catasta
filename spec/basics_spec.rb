# describe "CurlyCurly" do
#   def compile_ruby_template(name)
#     `ruby curly.rb -t Ruby -i spec/templates/#{name}.curly --no-header -`
#   end

#   sets = [
#     ["the static template", "static"],
#     ["templates with a variable", "variable"],
#     ["conditional templates", "conditional"]
#   ]
#   ext = {
#     "ruby" => "rb"
#   }

#   ["ruby"].each do |lang|
#     sets.each do |msg, name|
#       it "should evaluate #{msg} in #{lang}" do
#         compiled = method(:"compile_#{lang}_template").call(name)
#         compiled.should eq(File.read("spec/compiled/#{name}.#{ext[lang]}"))
#       end
#     end
#   end
# end

require 'rspec'
require "catasta/core/parslet_parser"

RSpec.configure do |config|
  # Use color in STDOUT
  config.color_enabled = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate
end

RSpec::Matchers.define :compile_to do |expected|
  match do |actual|
    # puts "parse: #{CatastaParser.new.parse(actual)}"
    parsed = CatastaParser.new.parse(actual)
    result = begin
      CatastaRubyTransform.new.apply(parsed).generate
    rescue
      puts "Failed while transforming" 
      pp parsed
      raise
    end
    @result = result
    result == expected
  end

  failure_message_for_should do |actual|
    "expected #{expected}, got #{@result}"
  end
end


describe CatastaRubyTransform do
  describe :basics do
    it "should process static text" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello world!
INPUT
puts "Hello world!\\n"
OUTPUT
    end

    it "should process evaluation" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello {{= name}}!
INPUT
puts "Hello "
puts _params[:name]
puts "!\\n"
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
  end
end