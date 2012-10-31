require 'fileutils'
require 'erb'
require 'pp'

module CurlyCurly::Java15
  class Writer
    def initialize(config, imports, code_tree, class_code)
      @config = config
      @template = ERB.new(File.read("java15/writer_template.erb"), nil, "<>")

      @imports = imports
      @code_tree = code_tree
      @class_code = class_code
    end
    
    def write(destination={})
      out = @config["out"] || "build/java15"
      if(destination[:to_directory])
        out = File.join(out, destination[:to_directory])
      end
      file = if(destination[:to_file])
        destination[:to_file]
      else
        the_class = (@config["class"] || "MyTemplate")
        File.join(out, the_class.split(".")[0..-2], the_class.split(".").last + ".java")
      end
      FileUtils.mkdir_p(File.dirname(file))
      
      methods = [
        StringBuilder.new(self),
        PrintWriter.new(self)
      ].map {|mg| mg.generate(@code_tree)}
      body = methods.join("\n")
      imports = @imports.to_a.sort.map {|i| "import #{i};"}.join("\n")
      class_code = @class_code
      header = true

      File.open(file, 'w') {|f| f.write(@template.result(binding))}
    end

    def add_import(import)
      @imports << import
    end
  end

  class MethodGenerator
    def initialize(writer)
      @writer = writer
    end
    def generate; end
  end

  class StringBuilder < MethodGenerator
    def initialize(*args)
      super
      @template = ERB.new(File.read("java15/method_template_string_builder.erb"), nil, "<>")
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
          "    " * indent + %{_sb.append("#{node.last}");}
        when :output
          "    " * indent + %{_sb.append(#{node.last});}
        end
      end.compact.join("\n")
    end
  end

  class PrintWriter < MethodGenerator
    def initialize(*args)
      super
      @template = ERB.new(File.read("java15/method_template_print_writer.erb"), nil, "<>")
    end
    def generate(tree)
      @writer.add_import("java.io.PrintWriter")
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
          "    " * indent + %{_pw.println("#{node.last}");}
        when :output
          "    " * indent + %{_pw.println(#{node.last});}
        end
      end.compact.join("\n")
    end
  end
end

