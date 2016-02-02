module Usable
  class ModExtender
    attr_accessor :copy, :mod, :config

    def initialize(mod, config = OpenStruct.new)
      @mod = mod
      @copy = has_spec? ? mod.const_get(:Spec).dup : mod.dup
      @config = config
    end

    def call
      copy.prepend override
    end

    def override
      unwanted = config.only ? copy.instance_methods - Array(config.only) : []
      Module.new do
        unwanted.each do |method_name|
          define_method(method_name) { |*| }
        end
      end
    end

    def has_spec?
      mod.const_defined?(:Spec)
    end
  end
end
