module Usable
  class Config < OpenStruct
    def modules
      @modules ||= []
    end

    def available_methods
      modules.each_with_object(Hash.new(default_method)) do |mod, result|
        mod.instance_methods.each do |method_name|
          result[method_name] = mod.instance_method method_name
        end
      end
    end

    def default_method
      Null.instance_method(:null)
    end

    module Null
      def null(*, &block)
      end
    end
  end
end
