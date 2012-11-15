module Catasta
  class Step
    def initialize(name, previous_step=nil)
      @name = name
      @previous_step = previous_step
      @tree = nil
      @data = {}
    end
    def next_step(name)
      self.class.new(name, self)
    end
    def tree=(tree)
      @tree = tree
    end
    def tree(copy_previous=true)
      if @tree
        @tree
      elsif @previous_step
        if copy_previous
          @tree = Marshal.load(Marshal.dump(@previous_step.tree(false)))
          @tree
        else
          @previous_step.tree(false)
        end
      else
        nil
      end
    end
    def lookup(name)
      if @name == name
        self
      elsif @previous_step
        @previous_step.lookup(name)
      else
        nil
      end
    end
    def [](key)
      @data[key]
    end
    def []=(key, value)
      @data[key] = value
    end
  end
end