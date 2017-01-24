module Usable
  module EagerLoad
    def eager_load!
      super.tap { Usable.freeze unless Usable.frozen? }
    end
  end
end
