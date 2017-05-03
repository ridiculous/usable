module Usable
  def self.Struct(attributes = {})
    Class.new do
      extend Usable

      self.usables = Usable::Config.new(attributes)

      attributes.keys.each do |key|
        define_method(key) { @attrs[key.to_sym] }
        define_method("#{key}=") { |new_val| @attrs[key.to_sym] = new_val }
      end

      attr_accessor :attrs

      def initialize(attrs = {})
        @attrs = usables.merge(attrs)
      end
    end
  end
end
