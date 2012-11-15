require_relative 'generator'
require_relative 'scoping'
require_relative 'type_renderer'
require "set"

module Catasta::Java15
class Generator < Catasta::Generator
  def visit(step)
    @config = step.lookup(:FrontMatter)[:front_matter]["Java15"]
    parser = step.lookup(:Parser)
    result = parse(parser.tree)
    step.tree = result[:code]
    step[:imports] = result[:imports]
    step[:class_code] = result[:class_code]
  end
  def parse(node)
    case node
    when Catasta::Node::Program
      # Initialization
      # Should happen only once per top-level call to #parse
      @scopes = []
      @type_renderer = TypeRenderer.new
      @imports = Set.new(["java.util.Map"])
      @class_code = []
      if @config.has_key? "parameters"
        scope = ArgumentScope.new
        @config["parameters"].each {|k, t| scope[k] = t}
        @scopes << scope
      end
      if @config.has_key? "imports"
        @filters = @config["imports"].inject({}) { |memo, (target_method, alia)|
          memo[alia] = target_method
          memo
        }
      else
        @filters = {}
      end
      code = node.children.map {|s| parse(s)}
      {imports: @imports, code: code, class_code: @class_code }
    when Catasta::Node::Text
      [:text, sanitize(node.text)]
    when Catasta::Node::IterateList
      @imports << "java.util.List"
      
      coll = node.collection
      loop_var = node.loop_var
      scope = lookup_scope(coll)
      coll_type = scope.get_type(coll)
      raise @gpv.make_compile_error("Can't iterate list-style over #{coll}", node) unless coll_type.is_a? Catasta::List
      value_type = coll_type.get_subtype(:value)
      coll_resolved = scope.resolve(coll)

      raise @gpv.make_compile_error("Loop variable '#{loop_var}' already in use", node) if @scopes.any? {|s| s.in_scope? loop_var}
      
      scope = LocalScope.new
      scope[loop_var] = value_type
      @scopes << scope
      result = [
        [:code, %|for(#{@type_renderer.simple_name(value_type)} #{loop_var} : (#{@type_renderer.simple_name(coll_type)})#{coll_resolved}){|],
          [:indent],
          node.children.map {|s| parse(s)},
          [:unindent],
        [:code, "}"]
      ]
      @scopes.pop
      result
    when Catasta::Node::IterateMap
      @imports << "java.util.Map"
      coll = node.collection
      key_var = node.loop_var_key
      value_var = node.loop_var_value

      scope = lookup_scope(coll)
      coll_type = scope.get_type(coll)
      coll_resolved = scope.resolve(coll)
      
      key_type = coll_type.get_subtype(:key)
      value_type = coll_type.get_subtype(:value)
      scope = LocalScope.new
      scope[key_var] = key_type
      scope[value_var] = value_type
      @scopes << scope
      
      generic_bits = %|<#{@type_renderer.simple_name(key_type)}, #{@type_renderer.simple_name(value_type)}>|
      result = [
        [:code, %|for(Map.Entry#{generic_bits} entry : ((#{@type_renderer.simple_name(coll_type)})#{coll_resolved}).entrySet()){|],
          [:indent]
      ]
      body = node.children.map {|s| parse(s)}
      if scope.get_resolve_count(key_var) > 0
        result << [:code, %|#{@type_renderer.simple_name(key_type)} #{key_var} = entry.getKey();|]
      end
      if scope.get_resolve_count(value_var) > 0
        result << [:code, %|#{@type_renderer.simple_name(value_type)} #{value_var} = entry.getValue();|]
      end
      result += [
          body,
          [:unindent],
        [:code, "}"]
      ]
      @scopes.pop
      result
    when Catasta::Node::Evaluate
      var = node.code
      result = evaluate(var)
      
      [:output, result]
    when Catasta::Node::ConditionalTruthy
      positive = node.positive
      var = node.variable
      scope = lookup_scope(var)
      resolved = scope.resolve(var)
      type = scope.get_type(var)
      type_string = @type_renderer.simple_name(type)
      top = case type
      when Catasta::Integer
        if positive
          "if(!(Integer.valueOf(0).equals(#{resolved}))) {"
        else
          "if(Integer.valueOf(0).equals(#{resolved}))) {"
        end
      when Catasta::String
        # Java 1.6 introduced String#isEmpty
        if positive
          %|if(!"".equals(#{resolved})) {|
        else
          %|if("".equals(#{resolved})) {|
        end
      when Catasta::Map
        @imports << "java.util.Map"
        if positive
          "if(#{resolved} != null && !((#{type_string})#{resolved}).isEmpty()) {"
        else
          "if(#{resolved} == null || ((#{type_string})#{resolved}).isEmpty()) {"
        end
      when Catasta::List
        @imports << "java.util.List"
        if positive
          "if(#{resolved} != null && ((#{type_string})#{resolved}).isEmpty()) {"
        else
          "if(#{resolved} == null || !((#{type_string})#{resolved}).isEmpty()) {"
        end
      else
        raise "Unexpected type in conditional: `#{scope.get_type(var)}`"
      end
      [
        [:code, top],
          [:indent],
          node.children.map {|s| parse(s)},
          [:unindent],
        [:code, "}"]
      ]
    else
      raise "Unrecognized symbol: #{node.inspect}"
    end
  end
  
  private
  
  def evaluate(var)
    var, filters = var.split("|", 2).map {|s| s.strip}
    result, type = case var
    when /^[a-zA-Z]+$/
      scope = lookup_scope(var)
      [scope.resolve(var), scope.get_type(var)]
    when /^\d+$/
      [var.to_i, Catasta::Integer.new]
    when /^"\w+"$/
      [var, Catasta::String.new]
    when /^[a-zA-Z]+(?:\.[a-zA-Z]+)+/
      parts = var.split(".")
      scope = lookup_scope(parts[0])
      raise "Invalid target for property lookup" unless scope.get_type(parts[0]).is_a? Catasta::Object
      @imports << "com.Catasta.core.PojoExtractor"
      @class_code << "private static final PojoExtractor _extractor = new PojoExtractor();"
      args = [parts[0]] + parts.drop(1).map {|p| %{"#{p}"}}
      ["_extractor.extract(#{args.join(", ")})", Catasta::Unknown.new]
    else
      raise "Can't evaluate `#{var}`"
    end

    if !filters.nil?
      filters = filters.split("|").map {|s| s.strip}
      filters.each do |filter|
        method = @filters[filter]
        raise "Can't resolve filter: #{filter}" unless method
        result = %{#{method}(#{result})}
      end
    end
    result
  end
  
  # Fix up newlines so they don't break Java's single-line strings.
  def sanitize(str)
    str.gsub(/\n/, '\n')
  end
  
  def lookup_scope(var)
    @scopes.reverse_each.find {|s| s.in_scope? var} or
      raise "Could not resolve var '#{var}'; looked in scopes #{@scopes}"
  end
end
end
