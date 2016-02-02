module Usable
  class ModExtender
    attr_accessor :mod, :copy, :options

    def initialize(mod, config = OpenStruct.new)
      @mod = mod
      @copy = mod.dup
      @config = config
      @unwanted = config.only ? mod.instance_methods - Array(config.only) : []
    end

    def override
      unwanted = @unwanted
      Module.new do
        unwanted.each do |method_name|
          define_method(method_name) { |*| }
        end
      end
    end

    def to_spec
      mod_spec = has_spec? ? mod.const_get(:Spec).dup : copy
      mod_spec.prepend override
    end

    def has_spec?
      mod.const_defined?(:Spec)
    end
  end
end
