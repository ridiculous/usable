module Usable
  module Persisted
    # = Stores usables in a yaml file

    extend Usable

    config do
      dir { defined?(Rails) ? Rails.root.join('tmp') : File.expand_path('..', __FILE__) }
    end

    def self.extended(base)
      base.extend Usable
      base.usable self
    end

    # Automatically copied over by +usable+
    module InstanceMethods
      # Accessor to read and write default ActiveRecord objects
      # When assigning a config, a reference to it is saved to tmp/<mod_name>.yml
      # and loaded in subsequent console sessions
      def method_missing(name, *args, &block)
        if block
          usables.public_send(name, &block)
        elsif name.to_s.end_with?('=') && args.length == 1
          _save name.to_s.tr('=', '').to_sym, args.pop
        elsif usables[name]
          usables[name]
        elsif _config[name]
          usables[name] = if _config[name].is_a?(Hash)
                            _config[name].fetch(:class).constantize.find(_config[name].fetch(:id))
                          else
                            _config[name]
                          end
        else
          usables.public_send(name) || super
        end
      end

      def has?(setting)
        !!send(setting)
      rescue NoMethodError => e
        if e.message.include?("method `#{setting}'")
          false
        else
          raise
        end
      end

      #
      # Private
      #

      def _save(key, val = nil)
        if val.nil?
          _config.delete(key)
        elsif val.respond_to?(:persisted?) && val.persisted?
          _config[key] = { class: val.class.name, id: val.id }
        else
          _config[key] = val
        end
        File.open(_config_file, 'wb') { |f| f.puts _config.to_yaml }
        usables[key] = val
      end

      def _config_file
        return @_config_file if @_config_file
        FileUtils.mkdir_p(usables.dir) unless File.directory?(usables.dir)
        @_config_file = File.join(usables.dir, "#{self.class.name.downcase.gsub('::', '_')}.yml")
        FileUtils.touch(@_config_file) unless File.exists?(@_config_file)
        @_config_file
      end

      def _config
        @_config ||= YAML.load_file(_config_file) || {}
      end
    end
  end
end
