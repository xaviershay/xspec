# # DSL

# Common DSL functions are provided as a module so that they can be used in
# both top-level and nested contexts. The method names are modeled after
# rspec, and should behave roughly the same.
#
# They delegate to method in the [current context](xspec.html#section-5) named
# in a way that more accurately represents XSpec implementation details.
module XSpec
  module DSL
    def it(*args, &block)
      __xspec_context.add_unit_of_work(*args, &block)
    end

    def describe(*args, &block)
      __xspec_context.add_child_context(*args, &block)
    end

    def let(*args, &block)
      __xspec_context.add_memoized_method(*args, &block)
    end

    def shared_context(*args, &block)
      __xspec_context.create_shared_context(*args, &block)
    end

    def include_context(context)
      __xspec_context.copy_into_tree(context)
    end
  end
end
