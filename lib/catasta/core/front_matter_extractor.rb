module Catasta
  class FrontMatterExtractor
    def initialize(ops)
      @ops = ops
    end
    def visit(step)
      step.tree.gsub!(/^(---.*)---\n/m) {|m| @front_matter = YAML.load_documents(m); ""}
      @front_matter = @front_matter.compact.inject({}){|memo, doc| memo[doc["target"]] = doc; memo}
      (@front_matter[nil] ||= {})["header"] = @ops[:header]
      @front_matter.each do |target, doc|
        next if target.nil?
        doc.replace(@front_matter[nil].merge(doc))
      end
      # @front_matter["Java"] = @front_matter["Java15"]
      # @front_matter["Ruby"] = @front_matter["Ruby19"]
      step[:front_matter] = @front_matter
    end
  end
end