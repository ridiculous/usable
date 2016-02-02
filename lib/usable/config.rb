module Usable
  class Config < OpenStruct
    def modules
      @modules ||= []
    end

    def available_methods
      modules.each_with_object({}) do |mod, result|
        mod.instance_methods.each do |method_name|
          result[method_name] = mod.instance_method method_name
        end
      end
    end
  end
end
