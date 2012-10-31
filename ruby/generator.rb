require 'erb'
require 'set'

require_relative '../common/generator'
require_relative '../common/util'
require_relative 'scoping'
require_relative "../common/nodes"

module CurlyCurly::Ruby
class Generator < CurlyCurly::Generator
  def process
    parse(@gpv.get)
  end
  def parse(node)
    case node
    when ::CurlyCurly::Node::Program
      # Initialization
      # Should happen only once per top-level call to #parse
      @scopes = []
      @indent = 1
      @imports = Set.new
      if @config.has_key? "parameters"
        scope = ArgumentScope.new
        @config["parameters"].each {|k, t| scope[k] = t}
        @scopes << scope
      end
      if @config.has_key? "imports"
        @filters = @config["imports"].inject({}) { |memo, (target_method, alia)|
          klass, method = target_method.split(".", 2)
          @imports << CurlyCurly::Util.underscore(klass)
          memo[alia] = target_method
          memo
        }
      else
        @filters = {}
      end
      code = node.children.map {|s| parse(s)}
      imports = @imports.to_a
      {:code => code, :imports => imports}
    when CurlyCurly::Node::Text
      [:text, node.text]
    when ::CurlyCurly::Node::IterateList
      coll = node.collection
      loop_var = node.loop_var

      scope = lookup_scope(coll)
      value_type = scope.get_type(coll).get_subtype(:value)
      coll = scope.resolve(coll)
      
      scope = LocalScope.new
      scope[loop_var] = value_type
      @scopes << scope
      result = [
        [:code, %{#{coll}.each do |#{loop_var}|}],
          [:indent],
          node.children.map {|s| parse(s)},
          [:unindent],
        [:code, "end"]
      ]
      @scopes.pop
      result
    when CurlyCurly::Node::IterateMap
      coll = node.collection
      key_var = node.loop_var_key
      value_var = node.loop_var_value
      scope = lookup_scope(coll)
      coll_resolved = scope.resolve(coll)
      
      key_type = scope.get_type(coll).get_subtype(:key)
      value_type = scope.get_type(coll).get_subtype(:value)
      scope = LocalScope.new
      scope[key_var] = key_type
      scope[value_var] = value_type
      @scopes << scope
      result = [
        [:code, %{#{coll_resolved}.each do |#{key_var}, #{value_var}|}],
          [:indent],
          node.children.map {|s| parse(s)},
          [:unindent],
        [:code, "end"]
      ]
      @scopes.pop
      result
    when CurlyCurly::Node::Evaluate
      code = node.code
      var, filters = code.split("|", 2).map {|s| s.strip}
      result, type = case var
      when /^[a-zA-Z]+$/
      
        scope = lookup_scope(var)
        [scope.resolve(var), scope.get_type(var)]
      when /^\d+$/
        [var.to_i, CurlyCurly::Integer.new]
      when /^"\w+"$/
        [var, CurlyCurly::String.new]
      when /^[a-zA-Z]+(?:\.[a-zA-Z]+)+/
        parts = var.split(".")
        scope = lookup_scope(parts[0])
        raise "Invalid target for property lookup" unless scope.get_type(parts[0]).is_a? CurlyCurly::Object
        # Splitting and joining on . is redundant, but this is just leaving an opening
        # to change the syntax later
        [parts.join("."), CurlyCurly::Unknown.new]
      else
        raise "Can't evaluate `#{var}`"
      end
      if !filters.nil?
        filters = filters.split("|").map {|s| s.strip}
        filters.each do |filter|
          method = @filters[filter]
          raise unless method
          result = %{#{method}(#{result})}
        end
      end
      [:output, result]
    when CurlyCurly::Node::ConditionalTruthy
      positive = node.positive
      var = node.variable
      scope = lookup_scope(var)
      resolved = scope.resolve(var)
      top = case scope.get_type(var)
      when CurlyCurly::Integer
        if positive
          "if #{resolved} != 0"
        else
          "if #{resolved} == 0"
        end
      when CurlyCurly::String
        if positive
          %{if #{resolved} != ""}
        else
          %{if #{resolved} == ""}
        end
      when CurlyCurly::Map, CurlyCurly::List # we /could/ use CurlyCurly::Collection here, but unsound
        if positive
          "if !#{resolved}.empty?"
        else
          "if #{resolved}.empty?"
        end
      else
        raise "Unexpected type in conditional: `#{scope.get_type(var)}`"
      end
      result = [
        [:code, top],
          [:indent],
          node.children.map {|s| parse(s)},
          [:unindent],
        [:code, "end"]
      ]
      result
    else
      raise "Unexpected token `#{node.inspect}`"
    end
  end
  
  private
  def pad(str, level)
    "  " * level + str
  end
  
  def lookup_scope(var)
    @scopes.reverse_each.find {|s| s.in_scope? var} or
      raise "Could not resolve var '#{var}'; looked in scopes #{@scopes}"
  end
end
end
