module Catasta::JavaScript
class Writer
	def initialize(options)
		@options = options
	end

	def apply(transformed)
		# puts "Options: #{@options.inspect}"
		# puts transformed
		class_name = @options[:input].split(".").first.capitalize
		template = <<EOF
(window.ctemplate = window.ctemplate || {}).#{class_name} = function(_params) {
	_params = _params || {};
	#{transformed.gsub(/\n/, "\n  ")}
};
EOF
		if @options[:output] == "-"
			puts template
		elsif File.directory? @options[:output]
			name = @options[:input].split(".").first + ".js"
			File.open("#{@options[:output]}/#{name}", 'w') {|h| h.write(template)}
		else
			raise ArgumentError, "Output was not - or a directory"
		end
	end
end
end
