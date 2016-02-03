# Usable

Rack style mixins for Ruby objects. Mount your modules like you mean it!

```ruby
module VersionKit
  def save_version
    "Saving up to #{self.class.usable_config.max_versions} versions to #{self.class.usable_config.table_name}"
  end

  def destroy_version
    "Deleting versions from #{self.class.usable_config.table_name}"
  end
end
  
class Model
  extend Usable

  usable VersionKit, only: :save_version do |config|
    config.max_versions = 10
    config.table_name = 'custom_versions'
  end
end

>> Model.usable_config.table_name
=> "custom_versions"
>> Model.new.save_version
=> "Saving up to 10 versions to custom_versions"
>> Model.usable_config.available_methods[:save_version].bind(self).call
=> "Saving up to 10 versions to custom_versions"
>> Model.new.respond_to? :destroy_version     
=> false
>> Model.usable_config.available_methods[:destroy_version].bind(self).call
=> nil
```
What's going on here? Well `#save_versions` is now extended onto the `Model` class, but `#destroy_version` is not!

## But wait, you undefined my methods?

Yes. Well ... yes, at least on the copy of the module included in the target class. But, checking if an object responds
to a method all time doesn't produce very [confident code](http://www.confidentruby.com/). That's why it is encouraged
to reference methods through the `Model.usable_config.available_methods` hash. This way you can confidently call methods,
just don't rely on the return value! Methods that are removed via `:only` will return `nil`.

## Seperate included module from configurable methods

Sometimes you want to define methods on the module but not have them be configurable. Define a module within the usable 
module namespace and name it `UsableSpec`, and `Usable` will use that module to configure the available methods. Any naming
conflicts will be resolved by giving precedence to the parent module.

For example:

```ruby
module VersionKit
  module UsableSpec
    def version
      "yo"
    end
  end
  
  def self.included(base)
    puts base.usable_config.available_methods[:version].bind(self).call
  end
end

>> Example = Class.new.extend Usable
=> Example
>> Example.usable VersionKit
yo
=> Example
>> Example.new.version
=> "yo"
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'usable'
```

Or install it yourself as:

    $ gem install usable

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/usable.

