# Usable [![Gem Version](https://badge.fury.io/rb/usable.svg)](http://badge.fury.io/rb/usable) [![Build Status](https://travis-ci.org/ridiculous/usable.svg)](https://travis-ci.org/ridiculous/usable) [![Code Climate](https://codeclimate.com/github/ridiculous/usable/badges/gpa.svg)](https://codeclimate.com/github/ridiculous/usable)

Usable provides an elegant way to mount and configure your modules. Class level settings can be configured on a per module basis,
available to both the module and including class. Allows you to include only the methods you want. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'usable'
```

## Usage

Configure a module to have "usable" defaults:
```ruby
module VersionMixin
  extend Usable

  config do
    max_versions 25
    table_name 'versions'
    observer { Class.new }
  end
  
  def save_version
    "Saving #{usables.max_versions} #{usables.table_name}"
  end

  def destroy_version
    "Deleting versions from #{usables.table_name}"
  end
end
```

Include the module into a class using `usable`, which will copy over the configs:
```ruby
class Model
  extend Usable

  usable VersionMixin, only: :save_version do
    max_versions 10
  end

  def save
    save_version
  end
end

model = Model.new
model.save_version         # => "Saving 10 versions"
model.destroy_version      # => NoMethodError: undefined method `destroy_version' for #<Model:...
model.usables.max_versions # => 10
model.usables.table_name   # => "version"
```

`Model` now has a `#save_versions` method but no `#destroy_version` method. Usable has effectively mixed in the given module
using `include`. Ruby 2+ offers the `prepend` method, which can be used instead by specifying it as the `:method` option:

```ruby
Model.usable VersionMixin, method: :prepend
```

A usable module can also be extended onto a class with `method: :extend`

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
    census({
      population: 1_400_00,
      daily_visitors: 218_150
    })
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

* `ClassMethods`
* `InstanceMethods`

## Notes

If the given module is modified by the `:only` option, then Usable will duplicate the module so that it doesn't mutate
it globally. Duplicating a module returns an anonymous module. But anonymous mods in the ancestor list can be confusing.
So Usable gives the modified module a name, which is the same name as the original module but with "Used" appended.

```ruby
Mixin => MixinUsed
```

## Tips and Tricks

#### __since 3.6__

Eager-load and freeze usables in production Rails environments with the `frozen` setting. Note that `config.cache_classes`
(Rails 3+) or `config.eager_load` (Rails 4+) must also be true, since it hooks into Rails' eager load process.

```ruby
config.usable_config.frozen = true
```

#### __since 3.4__

Import just a module's constants:

```ruby
usable ExampleMod, only: :constants
```

Currently works with `usable ExampleMod, only: []` since version 2.0

#### __since 3.3__ _- (not required)_
The `Usable::Struct` function is available for creating value objects with defaults. If you `require "usable/struct"` the
class function is available to create classes:

```ruby
class Route < Usable::Struct(paths: %w[api v2 v3])
end

Route.usables.to_h          # => {:paths=>["api", "v2", "v3"]}
Route.new.paths             # => ["api", "v2", "v3"] 
Route.new(paths: nil).paths # => nil
```

#### __since version 2.0__

When usable modules define the same config setting, the last one mounted takes precedence. Fortunately,
Usable also "stacks" config settings by namespacing them:

```ruby
module Robot
  extend Usable
  config do
    speak 'beep bop'
  end
end

module Human
  extend Usable
  config do
    speak 'Hello'
  end
end

class User
  extend Usable
  usable Human, Robot
end

User.usables.speak       # => "beep bop"
User.usables.human.speak # => "Hello"
User.usables.robot.speak # => "beep bop"
```

## Persisted Defaults

Stores usables to a yaml file, so config can be reloaded in subsequent sessions. Useful for setting some defaults to work with locally.

```ruby
begin
  require "usable"
  require "usable/persistence"
  # Stores commonly used variables across console sessions
  # e.g.
  # > oo.guide = Guide.last
  # > oo.guide
  def oo
    @oo ||= Class.new { extend Usable::Persistence }.new
  end
rescue LoadError
  puts "[INFO] Couldn't load `usable` gem. The helper method `oo` is unavailable for this session."
end
```

## Production

When running in production you may want to eager-load any lazily defined attributes and freeze them, ensuring thread safety.
Usable provides a [railtie](http://edgeguides.rubyonrails.org/configuring.html) that can be configured to freeze Usable and
and constants extended with Usable.

Enable the frozen setting:
```ruby
# config/production.rb
Acme::Application.configure do
  # Freeze all +usables+ after initialize, eager-loading any lazily defined attributes
  config.usable_config.frozen = true
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ridiculous/usable.

