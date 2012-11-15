require 'fileutils'
require 'erb'

module Catasta::Ruby
  class Writer
    def initialize(destination)
      @destination = destination

      template_path = "ruby/writer_template.erb"
      @template = ERB.new(File.read(template_path), nil, "<>")
      @template.filename = template_path
    end
    
    def visit(step)
      out = File.join(@destination[:to_directory], "ruby")
      @config = step.lookup(:FrontMatter)[:front_matter]["Ruby"]

      the_module = (@config["module"] || "").split("::")
      the_class = (@config["class"] || "Template")
      header = @config["header"]
      file = File.join(out, the_module, the_class + ".rb")
      FileUtils.mkdir_p(File.dirname(file))

      methods = [
        ArrayBuffer.new(self)
      ].map {|mg| mg.generate(step.tree)}
      body = methods.join("\n")
      imports = step.lookup(:RubyGenerator)[:imports].to_a.sort.map {|i| %{import "#{i}"}}.join("\n")
      class_code = nil

      File.open(file, 'w') {|f| f.write(@template.result(binding))}
    end
  end


  class MethodGenerator
    def initialize(writer)
      @writer = writer
    end
    def generate; end
  end

  class ArrayBuffer < MethodGenerator
    def initialize(*args)
      super
      @template = ERB.new(File.read("ruby/method_template_array_buffer.erb"), nil, "<>")
    end
    def generate(tree)
      code  = "  " * 3 + "_buf = []\n"
      code += "  " * 2 + generate_helper(tree).split("\n").join("\n" + "  " * 2) + "\n"
      code += "  " * 3 + %{_buf.join\n}
      code += "  " * 1
      @template.result(binding)
    end

    private
    def generate_helper(tree, indent=1)
      tree.map do |node|
        case node.first
        when Array
          generate_helper(node, indent)
        when :code
          "  " * indent + node.last
        when :indent
          indent += 1
          nil
        when :unindent
          indent -= 1
          nil
        when :text
          "  " * indent + %{_buf << "#{node.last}"}
        when :output
          "  " * indent + %{_buf << #{node.last}}
        end
      end.compact.join("\n")
    end
  end
end
