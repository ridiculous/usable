# Usable [![Gem Version](https://badge.fury.io/rb/usable.svg)](http://badge.fury.io/rb/usable) [![Build Status](https://travis-ci.org/ridiculous/usable.svg)](https://travis-ci.org/ridiculous/usable) [![Code Climate](https://codeclimate.com/github/ridiculous/usable/badges/gpa.svg)](https://codeclimate.com/github/ridiculous/usable)

Usable provides an elegant way to mount and configure your modules. Class level settings can be configured on a per module basis,
available to both the module and including class. Allows you to include only the methods you want. 

```ruby
module VersionMixin
  extend Usable
  usables[:max_versions] = 25
  usables[:table_name] = 'versions'
  
  def save_version
    "Saving up to #{usables.max_versions} versions to #{usables.table_name}"
  end

  def destroy_version
    "Deleting versions from #{usables.table_name}"
  end
end

class Model
  extend Usable

  usable VersionMixin, only: :save_version do
    max_versions 10
    table_name 'custom_versions'
  end

  def save
    usable_method(:save_version).call
  end
end

model = Model.new
model.save_version     # => "Saving up to 10 versions to custom_versions"
model.destroy_version  # => NoMethodError: undefined method `destroy_version' for #<Model:...
```
`Model` now has a `#save_versions` method but no `#destroy_version` method. Usable has effectively mixed in the given module
using `include`. Ruby 2+ offers the `prepend` method, which can be used instead by specifying it as the `:method` option:

```ruby
Model.usable VersionMixin, method: :prepend
```

Usable reserves the `:only` and `:method` keys. All other keys in the given hash are defined as config settings. If you really
want to define a config on the target class with one of these names, you can simply define them in the block:

```ruby
Model.usable VersionMixin, only: [:save_version] do
  only "Will be set on `Model.usables.only` and namespaced under `Model.usables.version_mixin.only`"
end
```

## Configuring Modules

Configuration settings defined on a "usable" module will be copied to the including class. Usable defines
a `config` method on extended modules (alias for `usables`) to use for setting default configuration options:

```ruby
module Mixin
  extend Usable
  config.language = :en
  config do
    country 'US'
    state 'Hawaii'
    spec :census, {
      population: 1_400_00,
      daily_visitors:  218_150
    }
  end
end

Model.usable Mixin
Model.usables[:state]                 # => 'Hawaii'
Model.usables.census[:daily_visitors] # => 218150
```

## Confidently calling methods

We should all be writing [confident code](http://www.confidentruby.com/), which is why you might want to call configurable
methods through the `usable_method` class and instance method. Methods passed in with the `:only` option
will _always_ return `nil` when called. Thus, the confidence.

Here's the same example as above, rewritten to call methods through the Usable interface:

```ruby
Model.usable_method(model, :save_version).call    # => "Saving up to 10 versions to custom_versions"
model.usable_method(:save_version).call           # => "Saving up to 10 versions to custom_versions"
Model.usable_method(model, :destroy_version).call # => nil
```

## Module Naming Conventions

Modules with the following names found within the target module's namespace will be automatically used.

`ClassMethods` - extended onto the target module.

`UsableSpec` - tells usable which methods are configurable via the `:only` option. Any naming conflicts will be resolved by 
giving precedence to the parent module.

For example:

```ruby
module Mixin
  def name
    "defined by Mixin"
  end

  def from_mixin
    "always here"
  end

  # @description Usable will apply the :only option to just the methods defined by this module
  module UsableSpec
    def from_spec
      "can be excluded"
    end

    def name
      "defined by UsableSpec"
    end
  end
end

class Example
  extend Usable
  usable Mixin, only: :from_spec
end

Example.new.from_spec   # => "can be excluded"
Example.new.from_mixin  # => "always here"
Example.new.name        # => "defined by Mixin"
Example.ancestors       # => [Example, Mixin, Example::MixinUsableSpecUsed, Object, Kernel, BasicObject] (ruby -v 2.3.0)
```

## Notes

If the given module is modified by the `:only` option, then Usable will duplicate the module so that it doesn't mutate
it globally. Duplicating a module returns an anonymous module. But anonymous mods in the ancestor list can be confusing.
So Usable gives the modified module a name, which is the same name as the original module but with "Used" appended.

```ruby
Mixin => MixinUsed
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'usable'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ridiculous/usable.

