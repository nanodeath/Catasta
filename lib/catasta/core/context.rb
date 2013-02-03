module Catasta
class Context
  attr_reader :scopes
  attr_reader :outputter
  attr_reader :data

  def initialize(options={})
    @scopes = []
    @outputter = options[:outputter] or raise "No outputter given"
    @path = (options[:path] || ENV["CATASTA_PATH"] || "").split(":")
    @transform = options[:transform]

    @indent = 0
    @whitespace = " "
    @indent_multiplier = 2
    @data = {}
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
  def render_file(partial_name)
    extensions = [".cat", ".cata", ".catasta"]
    result = nil
    file_matches = @path.product(extensions).map do |(path, extension)|
      candidate = File.join(path, "#{partial_name}#{extension}")
      if File.exist? candidate
        candidate
      else
        nil
      end
    end.compact
    if !file_matches.empty?
      parsed = Catasta::Parser.new.parse(File.read(file_matches.first))
      @transform.apply(parsed).generate(self).chomp
    else
      raise "File not found: #{partial_name}{#{extensions.join('|')}} (searched #{@path.inspect})."
    end
  end
end
end
