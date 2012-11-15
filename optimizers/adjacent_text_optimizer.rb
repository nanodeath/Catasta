require_relative './optimizer'

module Catasta
  class AdjacentTextOptimizer < Optimizer
    def optimize!(tree)
      idx = 0
      child1 = tree.children[idx]
      child2 = tree.children[idx+1]
      while child1 && child2
        if child1.is_a?(Node::Text) && child2.is_a?(Node::Text)
          child1.append(child2)
          tree.children.delete_at(idx+1)
        else
          if !child1.children.empty?
            optimize! child1
          end
          idx += 1
        end
        child1 = tree.children[idx]
        child2 = tree.children[idx+1]
      end
    end

    def get_level
      0
    end
  end
end
