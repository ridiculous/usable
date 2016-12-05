module Usable
  def self.Struct(attributes = {})
    Class.new do
      extend Usable

      self.usables = Usable::Config.new(attributes)

      define_singleton_method(:inherited) do |child|
        child.usables = usables.clone
      end

      attributes.keys.each do |key|
        define_method(key) { @attrs[key] }
        define_method("#{key}=") { |new_val| @attrs[key] = new_val }
      end

      attr_accessor :attrs

      def initialize(attrs = {})
        @attrs = usables.merge(attrs)
      end
    end
  end
end
