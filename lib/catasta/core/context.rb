module Catasta
class Context
  attr_reader :scopes
  attr_reader :outputter

  def initialize(options={})
    @scopes = []
    @outputter = options[:outputter] or raise "No outputter given"

    @indent = 0
    @whitespace = " "
    @indent_multiplier = 2
  end
  def write(obj, padding=true)
    if padding
      pad @outputter.print(obj)
    else
      @outputter.print(obj)
    end
  end
  def add_scope(scope)
    @scopes.unshift scope
    if block_given?
      body = yield
      pop_scope
      body
    end
  end
  def pop_scope
    @scopes.shift
  end
  def indent
    @indent += 1
    if block_given?
      body = yield
      unindent
      body
    end
  end
  def unindent
    @indent -= 1
  end
  def pad(str)
    @whitespace * @indent * @indent_multiplier + str
  end
end
end
