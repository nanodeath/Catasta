module CurlyCurly::Ruby
	class Template
		attr_reader :template_processor
		attr_reader :config
		attr_accessor :code
		attr_accessor :imports

		def initialize(template_processor, config={})
			@template_processor = template_processor
			@config = config[:config]
		end

		def apply_generator(generator)
			generator.process(self)
		end

		def apply_writer(writer)
			writer.process(self)
		end
	end
end