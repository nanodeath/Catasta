module CurlyCurly
  class Type
  end
  class Integer < Type
  end
  class Float < Type
  end
  class String < Type
  end
  class Object < Type
  end
  class Unknown < Type
  end

  class Collection < Type
  end
  class List < Collection
    def initialize(type)
      @contained_type = type
    end
    def get_subtype(slot)
      case slot
      when :value
        @contained_type
      end
    end
  end
  class Map < Collection
    def initialize(key_type, value_type)
      @key_type = key_type
      @value_type = value_type
    end
    
    def get_subtype(slot)
      case slot
      when :key
        @key_type
      when :value
        @value_type
      end
    end
  end
end
