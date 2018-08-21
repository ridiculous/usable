3.9.0 (8/20/2018)
=================

* Add `Usables#include?` to check whether the config has a requested key
* Fix bug when calling an unknown attribute on a frozen usable results in an exception (e.g. "can't modify frozen OpenStruct")

3.8.0 (5/5/2017)
=================

* Fix bug in `Usable::Struct` with string vs symbol keys
* Add `Usable.define_usable_accessors` to define class level accessors for the underlying usables
* Improve `Usable::Struct` to also define class accessors for the usables and behave like a hash with `[]` accessors
* Add `usables.merge! another: 'hash'` to easily update usables with hashes or other objects that respond to `:each`

3.7.1 (4/3/2017)
=================

* Fix segfault when extending module that extends self

3.7.0 (3/31/2017)
=================

* Usable modules will extend child modules with Usable and then copy their `usables` over (via `extended` and `included` hooks)
* Slim down files bundled into gem to only core files required

3.6.2 (1/23/2017)
=================

* Update Railtie to _always_ freeze Usable _after_ `Rails.application.eager_load!`
* Add `Usable.logger` to help debugging (default level: `Logger::ERROR`)

3.6.1 (1/23/2017)
=================

* Fix issue with trying to modify Usable.extended_constants when freezing Usable because it may eager-load subclasses of a class that extends Usable

3.6.0 (1/19/2017)
=================

* NEW - Add Rails setting `usable_config.frozen` to freeze Usable in a after initialize Railtie
* NEW - Add inherited hook to copy usable config to subclasses

3.5.0 (1/18/2017)
=================

* FIX - Can marshal Usable configs
* NEW - Track extended modules and constants so they can be eagerloaded and frozen in certain environments

3.4.0 (12/22/2016)
==================

* FIX - Copying usable attributes from a module to class/module works as expected
* NEW - Pass `only: :constants` when mounting a module to import just the constants from a module

3.3.0 (12/4/2016)
=================

* FIX - `Usable::ModExtender` doesn't require the target to be "usable"
* NEW - `Usable::Struct(a: :b)` creates value classes with defaults (optional `require 'usable/struct'`)
* NEW - `usables.merge` converts usables to a hash and merges w/ the other
* NEW - Usable::Config#initialize takes a hash to set the initial attributes
* NEW - Usable politely defines `.config(&block)`
* FIX - `usables.freeze` to also freeze `@spec` so errors are raised when modifying

3.2 (12/1/2016)
===============

* Improve performance of reads by defining usable attributes as methods
* `usables._spec` is now `usables.spec`

3.1 (11/30/2016)
================

* Convert +usables+ to a hash with +to_h+

3.0 (11/4/2016)
===============

* Multiple mods can be given to +usable+ simultaneously
* The +usables+ method no longer accepts a block (for performance reasons)
* Fix bug in Config#method_missing that was swallowing errors
* Fix bug in scoping Instance and Class method mods to the target module

2.2.1 (10/14/2016)
==================

* Usable config is copied correctly when extending a usable module

2.2.0 (9/30/2016)
==================

* [[PR #6](https://github.com/ridiculous/usable/pull/6))] Config options accept blocks that will be lazy loaded once and memoized for future calls
* [[Issue #4](https://github.com/ridiculous/usable/issues/4)] Fix bug in `Config#respond_to_missing?`

