module Usable
  class ModExtender
    attr_accessor :copy, :mod, :config

    def initialize(mod, config = OpenStruct.new)
      @mod = mod
      @copy = has_spec? ? mod.const_get(:Spec).dup : mod.dup
      @config = config
    end

    # @note Destructive
    def call
      override
      copy
    end

    def override
      unwanted = config.only ? copy.instance_methods - Array(config.only) : []
      unwanted.each do |method_name|
        copy.send :remove_method, method_name
      end
    end

    def has_spec?
      mod.const_defined?(:Spec)
    end
  end
end
