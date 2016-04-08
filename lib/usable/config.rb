module Usable
  class Config < BasicObject
    def each(&block)
      @spec.to_h.each(&block)
    end

    def spec(key, value = nil)
      @spec ||= ::OpenStruct.new
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

    def method_missing(method_name, *args, &_block)
      spec method_name, *args
    end

    def respond_to_missing?(method_name, _private = false)
      method_name.end_with?('=') || spec.respond_to?(method_name)
    end

    def available_methods
      modules.each_with_object(::Hash.new(default_method)) do |mod, result|
        mod.instance_methods.each do |method_name|
          result[method_name] = mod.instance_method method_name
        end
      end
    end

    def add_module(mod)
      modules << mod
    end

    def inspect
      ::Object.instance_method(:inspect).bind(self).call
    end

    alias_method :to_s, :inspect

    #
    # Internal
    #

    def modules
      @modules ||= []
    end

    #
    # Private
    #

    def default_method
      Null.instance_method(:default_method)
    end

    module Null
      def default_method(*, &block)
      end
    end
  end
end
