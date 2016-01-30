module Usable
  class Scoped
    module Configurable
      def configs
        @configs ||= Hash.new do |me, key|
          me[key] = Usable::Config.new
        end
      end
    end

    def self.extended(base)
      base.extend Configurable
    end

    def use(mod, options = {})
      send :include, mod unless self < mod
      if block_given?
        yield configs[mod]
      else
        options.each { |k, v| configs[mod].public_send "#{k}=", v }
      end
    end
  end
end

# @description TEST CASE
=begin
  module Versionable
    def versions
      config = self.class.configs[Versionable]
      "Saving #{config.max_versions} versions to #{config.table_name}"
    end
  end
  module Notable
    def notes
      config = self.class.configs[Notable]
      "Saving #{config.max_versions} notes to #{config.table_name}"
    end
  end
  class Model
    extend Usable::Scoped

  # with options hash
    use Versionable, table_name: 'custom_versions'
  # or with block
    use Versionable do |config|
      config.max_versions = 10
    end
    use Notable do |config|
      config.max_versions = 20
      config.table_name = 'custom_notes'
    end
  end
  Model.config.table_name #=> 'custom_versions'
  Model.new.versions #=> "Saving 10 versions to custom_versions"
  Model.new.notes #=> "Saving 20 notes to custom_notes"
=end
