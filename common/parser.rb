require_relative "parser"
require_relative "nodes"
require 'pry'

module CurlyCurly
class CompileError < StandardError
  attr_reader :line_number
  def initialize(msg, line_number)
    super("Line #{line_number}: #{msg}")
    @line_number = line_number
  end
end

class NodeListener
  def initialize(parser)
    @parser = parser
  end
  def node_added(node); end
end
class LineNumberListener < NodeListener
  def initialize(*args)
    super
    @line_numbers = {}
  end

  def node_added(node)
    @line_numbers[node] = @parser.line_number
  end

  def get_line_number(node)
    @line_numbers[node]
  end
end

class Parser
  def initialize(curly)
    @curly = curly
    @root = Node::Program.new
    @current_node = @root
    @listeners = []
    @line_number_listener = LineNumberListener.new(self)
    @listeners << @line_number_listener
  end

  def add_listener(listener)
    @listeners << listener
  end

  def make_compile_error(msg, node)
    CompileError.new(msg, node_to_line_number(node))
  end

  def node_to_line_number(node)
    @line_number_listener.get_line_number(node)
  end

  attr_reader :line_number
  def visit_line(line, line_number)
    @line_number = line_number
    offset = 0
    next_command = line.index(/{{(\d+)}}/, offset)
    while !next_command.nil?
      tag_match = $~
      intermediate_text = line[offset...next_command]

      @current_node.add_instruction Node::Text.new(intermediate_text)
      tag_match_idx = tag_match[1].to_i
      command = @curly.commands[tag_match_idx].strip

      if command.start_with? "="
        expression = command[1..-1].strip
        add_node(Node::Evaluate.new(code: expression))
      elsif m = command.match(/^for (?<var>\w+) in (?<container>\w+)$/)
        add_and_switch_to_node(Node::IterateList.new(collection: m["container"], loop_var: m["var"]))
      elsif m = command.match(/^for (?<var_key>\w+), (?<var_value>\w+) in (?<container>\w+)$/)
        add_and_switch_to_node(Node::IterateMap.new(collection: m["container"], loop_var_key: m["var_key"], loop_var_value: m["var_value"]))
      elsif m = command.match(/^if (?<negation>!)?(?<var>\w+)$/)
        add_and_switch_to_node(Node::ConditionalTruthy.new(positive: m["negation"].nil?, variable: m["var"]))
      elsif command.start_with? "/"
        close_current_node
      else
        raise "Unrecognized command: `#{command}`"
      end

      offset += intermediate_text.size + tag_match[0].size
      next_command = line.index(/{{(\d+)}}/, offset)
    end
    if offset < line.size
      intermediate_text = line[offset..-1]
      add_node(Node::Text.new(intermediate_text))
    end
  end

  def add_node(node)
    @current_node.add_instruction(node)
    @listeners.each {|v| v.node_added(node)}
  end

  def add_and_switch_to_node(node)
    add_node(node)
    @current_node = node
  end

  def close_current_node
    @current_node = @current_node.parent
  end

  def get
    @root
  end
end
end
