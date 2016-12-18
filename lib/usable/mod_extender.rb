module Usable
  class ModExtender
    attr_reader :name
    attr_accessor :copy, :mod, :options, :unwanted

    def initialize(mod, options = {})
      @mod = mod
      @options = options
      @options[:method] ||= :include
      @copy = mod
      @name = mod.name
      @unwanted = find_unwanted_methods(options[:only])
      if @unwanted.any?
        @copy = @copy.dup
      end
    end

    # @description Directly include a module whose methods you want made available in +usables.available_methods+
    #   Gives the module a name when including so that it shows up properly in the list of ancestors
    def call(target)
      unwanted.each do |method_name|
        copy.send :remove_method, method_name
      end
      if copy.name.nil?
        const_name = "#{mod_name}Used"
        target.send :remove_const, const_name if target.const_defined? const_name, false
        target.const_set const_name, copy
      end
      target.usables.add_module copy if target.respond_to?(:usables)
      target.send options[:method], copy
    end

    def mod_name
      if name
        name.split('::').last
      else
        "UsableMod#{Time.now.strftime('%s')}"
      end
    end

    def find_unwanted_methods(only)
      return [] unless only
      if :constants == only
        @copy.instance_methods
      else
        @copy.instance_methods - Array(only)
      end
    end
  end
end
