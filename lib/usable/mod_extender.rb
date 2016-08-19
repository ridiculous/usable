module Usable
  class ModExtender
    CLASS_MODULE = :ClassMethods

    attr_reader :name
    attr_accessor :copy, :mod, :options, :unwanted

    def initialize(mod, options = {})
      @mod = mod
      @options = options
      @options[:method] ||= :include
      @copy = mod
      @name = mod.name
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

    # @description Directly include a module whose methods you want made available in +usables.available_methods+
    #   Gives the module a name when including so that it shows up properly in the list of ancestors
    def use!(target)
      override
      if copy.name.nil?
        const_name = "#{mod_name}Used"
        target.send :remove_const, const_name if target.const_defined? const_name, false
        target.const_set const_name, copy
      end
      target.usables.add_module copy
      target.send options[:method], copy
    end

    # @description Extends the target with the module's ClassMethod mod
    def use_class_methods!(target)
      return unless mod.const_defined? CLASS_MODULE
      target.extend mod.const_get CLASS_MODULE
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
