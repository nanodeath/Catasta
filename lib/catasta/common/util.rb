module CurlyCurly
  class Util
    # not used yet
    def escape_double_quotes(str)
      str.gsub(/\"/, "\\\"")
    end

    def self.underscore(str)
      str.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
  end
end

