require 'fileutils'
require 'erb'
require 'pp'

module CurlyCurly::Javascript5
  class Writer
    def initialize(config, code_tree, class_code)
      @config = config
      @template = ERB.new(File.read("javascript5/writer_template.erb"), nil, "<>")

      @code_tree = code_tree
      @class_code = class_code
    end
    
    def write(destination={})
      out = @config["out"] || "build/javascript5"
      if(destination[:to_directory])
        out = File.join(out, destination[:to_directory])
      end
      file = if(destination[:to_file])
        destination[:to_file]
      else
        the_class = (@config["class"] || "MyTemplate")
        File.join(out, the_class.split(".")[0..-2], the_class.split(".").last + ".js")
      end
      FileUtils.mkdir_p(File.dirname(file))
      
      methods = [
        StringConcatenator.new(self)
      ].map {|mg| mg.generate(@code_tree)}
      body = methods.join("\n")
      class_code = @class_code
      header = true

      File.open(file, 'w') {|f| f.write(@template.result(binding))}
    end
  end

  class MethodGenerator
    def initialize(writer)
      @writer = writer
    end
    def generate; end
  end

  class StringConcatenator < MethodGenerator
    def initialize(*args)
      super
      @template = ERB.new(File.read("javascript5/method_template_string_concatenator.erb"), nil, "<>")
    end
    def generate(tree)
      code = generate_helper(tree)
      @template.result(binding)
    end

    private
    def generate_helper(tree, indent=1)
      tree.map do |node|
        case node.first
        when Array
          generate_helper(node, indent)
        when :code
          "    " * indent + node.last
        when :indent
          indent += 1
          nil
        when :unindent
          indent -= 1
          nil
        when :text
          "    " * indent + %{_ret += "#{node.last}";}
        when :output
          "    " * indent + %{_ret += #{node.last};}
        end
      end.compact.join("\n")
    end
  end
end

