module Usable
  # Store and manage configuration settings. Keep methods to a minimum since this class relies on method_missing to read
  # and write to the underlying @spec object
  class Config
    include ModConfig

    def initialize
      @spec = OpenStruct.new
    end

    def each(&block)
      @spec.to_h.each(&block)
    end

    def spec(key, value = nil)
      if value
        @spec[key.to_s.tr('=', '')] = value
      else
        @spec[key]
      end
    end

    def [](key)
      spec key
    end

    def []=(key, val)
      spec key, val
    end

    def method_missing(method_name, *args)
      spec method_name, *args
    rescue
      super
    end

    def respond_to_missing?(method_name, _private = false)
      method_name.to_s.end_with?('=') || @spec.respond_to?(method_name)
    end
  end
end
