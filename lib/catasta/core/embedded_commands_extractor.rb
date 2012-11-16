module Catasta
  class EmbeddedCommandsExtractor
    def initialize(ops)
      @ops = ops
      @commands = []
    end
    def visit(step)
      step.tree.gsub!(/{{(.+?)}}/) {|m| @commands.push($1); "{{#{@commands.size-1}}}"}
      step[:commands] = @commands
    end
  end
end