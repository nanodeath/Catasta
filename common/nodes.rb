module Catasta
module Node
  class Node
    def initialize(opts={})
      @children = []
      @parent = nil
      @root = nil
    end
    def add_instruction(node)
      @children << node
      node.parent = self
      node.root = self.root
    end
    
    attr_reader :parent
    attr_reader :children
    attr_reader :root
    protected
    def parent=(p)
      @parent = p
    end
    def root=(r)
      @root = r
    end
  end
  class Program < Node
    def root
      self
    end
  end
  class Text < Node
    attr_reader :text
    def initialize(text)
      super
      @text = text
    end
    def append(other_text_node, separator="\\n")
      @text += separator + other_text_node.text
    end
  end
  class Evaluate < Node
    attr_reader :code
    def initialize(opts={})
      super
      @code = opts[:code]
    end
  end
  class IterateList < Node
    attr_reader :collection
    attr_reader :loop_var
    def initialize(opts={})
      super
      @collection = opts[:collection]
      @loop_var = opts[:loop_var]
    end
  end
  class IterateMap < Node
    attr_reader :collection
    attr_reader :loop_var_key
    attr_reader :loop_var_value
    def initialize(opts={})
      super
      @collection = opts[:collection]
      @loop_var_key = opts[:loop_var_key]
      @loop_var_value = opts[:loop_var_value]
    end
  end
  class ConditionalTruthy < Node
    attr_reader :positive
    attr_reader :variable
    def initialize(opts={})
      super
      @positive = opts[:positive]
      @variable = opts[:variable]
    end
  end
end
end