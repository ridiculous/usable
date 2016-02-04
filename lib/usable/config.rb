module Usable
  class Config < OpenStruct
    def modules
      @modules ||= []
    end

    def add_module(mod)
      modules << mod
    end

    def available_methods
      modules.each_with_object(Hash.new(default_method)) do |mod, result|
        mod.instance_methods.each do |method_name|
          result[method_name] = mod.instance_method method_name
        end
      end
    end

    def default_method
      Null.instance_method(:default_method)
    end

    module Null
      def default_method(*, &block)
      end
    end
  end
end
