3.6.0 (1/19/2016)
=================

* NEW - Add Rails setting `usable_config.frozen` to freeze Usable in a after initialize Railtie
* NEW - Add inherited hook to copy usable config to subclasses

3.5.0 (1/18/2016)
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

