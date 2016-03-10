module Usable
  class ModExtender
    attr_reader :name
    attr_accessor :copy, :mod, :options, :unwanted

    def initialize(mod, options = {})
      @mod = mod
      @options = options
      @options[:method] ||= :include
      if has_spec?
        @copy = mod.const_get(:UsableSpec)
        @name = "#{mod.name}UsableSpec"
      else
        @copy = mod
        @name = mod.name
      end
      @unwanted = options[:only] ? @copy.instance_methods - Array(options[:only]) : []
      if @unwanted.any?
        @copy = @copy.dup
      end
    end

    # @note Destructive, as it changes @copy
    def override
      unwanted.each do |method_name|
        copy.send :remove_method, method_name
      end
    end

    # @description Directly include a module whose methods you want made available in +usable_config.available_methods+
    #   Gives the module a name when including so that it shows up properly in the list of ancestors
    def use!(target)
      override
      if copy.name.nil?
        const_name = "#{mod_name}Used"
        target.send :remove_const, const_name if target.const_defined? const_name, false
        target.const_set const_name, copy
      end
      target.usable_config.modules << copy
      target.send options[:method], copy
    end

    # @description Sends the method to the target with the original module
    def use_original!(target)
      return unless has_spec?
      target.usable_config.modules << mod
      target.send options[:method], mod
    end

    def has_spec?
      mod.const_defined?(:UsableSpec)
    end

    def mod_name
      if name
        name.split('::').last
      else
        "UsableMod#{Time.now.strftime('%s')}"
      end
    end
  end
end
