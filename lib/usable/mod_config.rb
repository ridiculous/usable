module Usable
  # Keep track of "used" modules and their "available" methods
  module ModConfig
    def available_methods
      modules.each_with_object(Hash.new(Null.instance_method(:default_method))) do |mod, result|
        mod.instance_methods.each do |method_name|
          result[method_name] = mod.instance_method method_name
        end
      end
    end

    def add_module(mod)
      modules << mod
    end

    def modules
      @modules ||= []
    end

    module Null
      def default_method(*, &_block)
      end
    end
  end
end
