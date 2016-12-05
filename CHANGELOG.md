3.2.1 (pending)
===============

* NEW - Usable politely defines `.config(&block)`
* FIx `usables.freeze` to also freeze `@spec` so errors are raised when modifying

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

