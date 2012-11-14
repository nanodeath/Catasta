require 'fileutils'
require 'erb'
require 'active_support/inflector'

module CurlyCurly::Ruby
  class Writer
    attr_reader :writer_template
    def initialize
      writer_template_path = "ruby/writer_template.erb"
      @writer_template = ERB.new(File.read(writer_template_path), nil, "<>")
      @writer_template.filename = writer_template_path
    end

    def process(destination, generated, config)
      Instance.new(self, destination, generated, config).result
    end

    class Instance
      def initialize(writer, destination, generated, config)
        @destination = destination
        @writer = writer
        @generated = generated
        @config = config
        process
      end

      def process
        imports = @generated[:imports]
        code_tree = @generated[:code]

        out = @config["out"] || "build/ruby"
        if(@destination[:to_directory])
          out = File.join(out, @destination[:to_directory])
        end
        relative_path = Pathname.new(@writer.writer_template.path).relative_path_from(Pathname.new(template.template_processor.root_folder))
        the_module = relative_path.dirname.to_s.split("/")[1..-1]
        the_class = relative_path.basename(".cts").to_s
        header = config["header"]
        file = if(@destination[:to_file])
          @destination[:to_file]
        else
          File.join(out, the_module, the_class + ".rb")
        end
        the_module = the_module.map {|m| m.camelize}
        the_class = the_class.camelize
        FileUtils.mkdir_p(File.dirname(file))

        methods = [
          ArrayBuffer.new(self)
        ].map {|mg| mg.generate(code_tree)}
        body = methods.join("\n")
        imports = imports.to_a.sort.map {|i| %{import "#{i}"}}.join("\n")

        if(file == "-")
          puts @writer.template.result(binding)
        else
          File.open(file, 'w') {|f| f.write(@writer.writer_template.result(binding))}
        end
      end
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
