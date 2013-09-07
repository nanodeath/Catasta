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

    it "should process evaluation of integers" do
      <<INPUT.should compile_to(<<OUTPUT)
Hello, it is {{= 1}} o'clock!  '
INPUT
_arr.push("Hello, it is ");
_arr.push(1);
_arr.push(" o'clock!  '\\n");
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
_arr.push("<ol>\\n");
(_params['content'] || []).forEach(function(c){
  _arr.push("  <li>");
  _arr.push(c);
  _arr.push("</li>\\n");
});
_arr.push("</ol>\\n");
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
_arr.push("<ol>\\n");
(_params['content'] || []).forEach(function(c, _c_index){
  _arr.push("  <li>");
  _arr.push(_c_index);
  _arr.push(": ");
  _arr.push(c);
  _arr.push("</li>\\n");
});
_arr.push("</ol>\\n");
OUTPUT
    end

    it "should process basic conditionals" do
      # Objects?
      <<INPUT.should compile_to(<<OUTPUT)
{{if monkey}}
  Monkey is truthy.
{{/if}}
INPUT
if(((_params['monkey'] === true) || (typeof _params['monkey'] === "string" && _params['monkey'] !== "") || (typeof _params['monkey'] === "number" && _params['monkey'] !== 0) || (typeof _params['monkey'] === "object" && Object.keys(_params['monkey']).length > 0))) {
  _arr.push("  Monkey is truthy.\\n");
}
OUTPUT
    end

    it "should process basic inverse conditionals" do
      <<INPUT.should compile_to(<<OUTPUT)
{{if !monkey}}
  Monkey is falsey.
{{/if}}
INPUT
if(((_params['monkey'] === null) || (_params['monkey'] === false) || (_params['monkey'] === "") || (_params['monkey'] === 0) || (typeof _params['monkey'] === "object" && Object.keys(_params['monkey']).length === 0))) {
  _arr.push("  Monkey is falsey.\\n");
}
OUTPUT
    end

    it "should process else blocks" do
      <<INPUT.should compile_to(<<OUTPUT)
{{if monkey}}
  Monkey is truthy.
{{else}}
  Monkey is falsey.
{{/if}}
INPUT
if(((_params['monkey'] === true) || (typeof _params['monkey'] === "string" && _params['monkey'] !== "") || (typeof _params['monkey'] === "number" && _params['monkey'] !== 0) || (typeof _params['monkey'] === "object" && Object.keys(_params['monkey']).length > 0))) {
  _arr.push("  Monkey is truthy.\\n");
} else {
  _arr.push("  Monkey is falsey.\\n");
}
OUTPUT
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
if(((_params['monkey'] === true) || (typeof _params['monkey'] === "string" && _params['monkey'] !== "") || (typeof _params['monkey'] === "number" && _params['monkey'] !== 0) || (typeof _params['monkey'] === "object" && Object.keys(_params['monkey']).length > 0)) && ((_params['banana'] === true) || (typeof _params['banana'] === "string" && _params['banana'] !== "") || (typeof _params['banana'] === "number" && _params['banana'] !== 0) || (typeof _params['banana'] === "object" && Object.keys(_params['banana']).length > 0))) {
  _arr.push("  Monkey and banana are truthy.\\n");
}
if(((_params['dog'] === true) || (typeof _params['dog'] === "string" && _params['dog'] !== "") || (typeof _params['dog'] === "number" && _params['dog'] !== 0) || (typeof _params['dog'] === "object" && Object.keys(_params['dog']).length > 0)) || ((_params['banana'] === true) || (typeof _params['banana'] === "string" && _params['banana'] !== "") || (typeof _params['banana'] === "number" && _params['banana'] !== 0) || (typeof _params['banana'] === "object" && Object.keys(_params['banana']).length > 0))) {
  _arr.push("  Dog or banana are truthy.\\n");
}
OUTPUT
    end

    it "should process multiple binary boolean logic" do
      <<INPUT.should compile_to(<<OUTPUT)
{{if monkey and banana and cat}}
  Monkey and banana and cat are truthy.
{{/if}}
INPUT
if(((_params['monkey'] === true) || (typeof _params['monkey'] === "string" && _params['monkey'] !== "") || (typeof _params['monkey'] === "number" && _params['monkey'] !== 0) || (typeof _params['monkey'] === "object" && Object.keys(_params['monkey']).length > 0)) && ((_params['banana'] === true) || (typeof _params['banana'] === "string" && _params['banana'] !== "") || (typeof _params['banana'] === "number" && _params['banana'] !== 0) || (typeof _params['banana'] === "object" && Object.keys(_params['banana']).length > 0)) && ((_params['cat'] === true) || (typeof _params['cat'] === "string" && _params['cat'] !== "") || (typeof _params['cat'] === "number" && _params['cat'] !== 0) || (typeof _params['cat'] === "object" && Object.keys(_params['cat']).length > 0))) {
  _arr.push("  Monkey and banana and cat are truthy.\\n");
}
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
if(((_params['monkey'] === true) || (typeof _params['monkey'] === "string" && _params['monkey'] !== "") || (typeof _params['monkey'] === "number" && _params['monkey'] !== 0) || (typeof _params['monkey'] === "object" && Object.keys(_params['monkey']).length > 0)) || ((_params['banana'] === true) || (typeof _params['banana'] === "string" && _params['banana'] !== "") || (typeof _params['banana'] === "number" && _params['banana'] !== 0) || (typeof _params['banana'] === "object" && Object.keys(_params['banana']).length > 0)) && ((_params['cat'] === true) || (typeof _params['cat'] === "string" && _params['cat'] !== "") || (typeof _params['cat'] === "number" && _params['cat'] !== 0) || (typeof _params['cat'] === "object" && Object.keys(_params['cat']).length > 0))) {
  _arr.push("  Monkey or banana and cat are truthy.\\n");
}
if(((_params['monkey'] === true) || (typeof _params['monkey'] === "string" && _params['monkey'] !== "") || (typeof _params['monkey'] === "number" && _params['monkey'] !== 0) || (typeof _params['monkey'] === "object" && Object.keys(_params['monkey']).length > 0)) && ((_params['banana'] === true) || (typeof _params['banana'] === "string" && _params['banana'] !== "") || (typeof _params['banana'] === "number" && _params['banana'] !== 0) || (typeof _params['banana'] === "object" && Object.keys(_params['banana']).length > 0)) || ((_params['cat'] === true) || (typeof _params['cat'] === "string" && _params['cat'] !== "") || (typeof _params['cat'] === "number" && _params['cat'] !== 0) || (typeof _params['cat'] === "object" && Object.keys(_params['cat']).length > 0))) {
  _arr.push("  Monkey and banana or cat are truthy.\\n");
}
OUTPUT
    end

    it "should process scoped multiple binary boolean logic" do
      <<INPUT.should compile_to(<<OUTPUT)
{{if (monkey or banana) and cat}}
  (Monkey or banana) and cat are truthy.
{{/if}}
INPUT
if((((_params['monkey'] === true) || (typeof _params['monkey'] === "string" && _params['monkey'] !== "") || (typeof _params['monkey'] === "number" && _params['monkey'] !== 0) || (typeof _params['monkey'] === "object" && Object.keys(_params['monkey']).length > 0)) || ((_params['banana'] === true) || (typeof _params['banana'] === "string" && _params['banana'] !== "") || (typeof _params['banana'] === "number" && _params['banana'] !== 0) || (typeof _params['banana'] === "object" && Object.keys(_params['banana']).length > 0))) && ((_params['cat'] === true) || (typeof _params['cat'] === "string" && _params['cat'] !== "") || (typeof _params['cat'] === "number" && _params['cat'] !== 0) || (typeof _params['cat'] === "object" && Object.keys(_params['cat']).length > 0))) {
  _arr.push("  (Monkey or banana) and cat are truthy.\\n");
}
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
_arr.push("<ol>\\n");
Object.keys(_params['content']).forEach(function(k){
  var v = _params['content'][k];
  _arr.push("  <li>");
  _arr.push(k);
  _arr.push(": ");
  _arr.push(v);
  _arr.push("</li>\\n");
}
_arr.push("</ol>\\n");
OUTPUT
    end

    it "should process partials" do
      <<INPUT.should compile_to(<<OUTPUT)
<div class="person">
  {{> person}}
</div>
INPUT
_arr.push('<div class="person">\\n  ');
_arr.push("Name: ");
_arr.push(_params['name']);
_arr.push("</div>\\n");
OUTPUT
    end
=begin
=end
  end
end