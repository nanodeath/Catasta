module Catasta
  class OptimizerList
    def initialize(*optimizers)
      @optimizers = optimizers
    end
    def visit(step)
      @optimizers.each do |o|
        o.optimize! step.tree
      end
    end
  end
end