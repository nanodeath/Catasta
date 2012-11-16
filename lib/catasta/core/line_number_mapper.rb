module Catasta
  class LineNumberMapper
    def initialize
      @source = {}
    end
    
    def visit(step)
      step.tree.split("\n").each_with_index do |line, idx|
        visit_line(line, idx+1)
      end
      step[:visitor] = self
    end

    def get_line(line_number)
      @source[line_number_to_key(line_number)]
    end

    private
    def visit_line(line, line_number)
      @source[line_number_to_key(line_number)] = line
    end
    def line_number_to_key(line_number)
      :"line_#{line_number}"
    end
  end
end