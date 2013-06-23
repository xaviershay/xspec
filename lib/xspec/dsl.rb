# Common DSL functions are provided as a module so that they can be used in
# both top-level and nested contexts. The method names are modeled after
# rspec, and should behave roughly the same.
module XSpec
  module DSL
    def it(*args, &block)
      __xspec_context.add_unit_of_work(*args, &block)
    end

    def describe(*args, &block)
      __xspec_context.add_child_context(*args, &block)
    end

    def let(*args, &block)
      __xspec_context.add_memoized_local(*args, &block)
    end
  end
end
