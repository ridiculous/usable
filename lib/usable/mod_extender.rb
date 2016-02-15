module Usable
  class ModExtender
    attr_reader :name
    attr_accessor :copy, :mod, :config

    def initialize(mod, config = OpenStruct.new)
      @mod = mod
      if has_spec?
        @copy = mod.const_get(:UsableSpec).dup
        @name = "#{mod.name}UsableSpec"
      else
        @copy =  mod.dup
        @name = mod.name
      end
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
      mod.const_defined?(:UsableSpec)
    end
  end
end
