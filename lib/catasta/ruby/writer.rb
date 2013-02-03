module Catasta::Ruby
class Writer
	def initialize(options)
		@options = options
	end

	def apply(transformed)
		# puts "Options: #{@options.inspect}"
		# puts transformed
		class_name = @options[:input].split(".").first.capitalize
		template = <<EOF
module Template
  class #{class_name}
    def template(_params={})
      #{transformed.gsub(/\n/, "\n      ")}
    end
  end
end
EOF
		if @options[:output] == "-"
			puts template
		elsif File.directory? @options[:output]
			name = @options[:input].split(".").first + ".rb"
			File.open("#{@options[:output]}/#{name}", 'w') {|h| h.write(template)}
		end
	end
end
end
