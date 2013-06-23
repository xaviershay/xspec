# XSpec data structures are very dumb. They:
#
# * Only contain iteration and creation logic.
# * Do not store recursive references ("everything flows downhill").
module XSpec
  # A unit of work, usually created via `Describe#it`, is a labeled code block
  # that expresses an assertion about a property of the system under test. They
  # are indivisible.
  #
  # These are run by an evaluator.
  UnitOfWork = Struct.new(:name, :block)

  # A context is a recursively nested structure, usually created with the
  # `describe` DSL method, that contains other contexts and units of work.
  # They are optional to use explicitly - extending `Xspec.dsl` will create
  # an implicit one - but are useful for organising your tests.
  #
  # Extra methods (or "locals") can be added throughout the lifetime of the
  # context, either by a normal `def` or using `let` helper. These methods are
  # inherited by nested contexts. An assertion context is extended on to this
  # object as a final step to make assertion methods available as instance
  # methods. The evaluator will then execute units of work inside the context,
  # making all the added methods available to the test.
  require 'xspec/dsl'
  class Context

    def __xspec_context; self; end
    include ::XSpec::DSL

    attr_reader :name, :children, :units_of_work, :locals, :assertion_context

    def initialize(name, assertion_context)
      @children          = []
      @units_of_work     = []
      @locals            = {}
      @name              = name
      @assertion_context = assertion_context
    end

    def add_child_context(name, opts = {}, &block)
      x = Class.new(self.class).new(name, assertion_context)
      x.instance_exec(&block)
      x.apply_assertion_context!
      self.children << x
    end

    # The assertion context should be applied after the user has had a chance
    # to add their own methods. It needs to be last so that users can't clobber
    # the assertion methods.
    def apply_assertion_context!
      extend(assertion_context)
    end

    def add_unit_of_work(name = nil, opts = {}, &block)
      self.units_of_work << UnitOfWork.new(name, block)
    end

    def add_memoized_local(name, &block)
      self.class.send(:define_method, name, &memoize(&block))
    end

    # A recursive iteration that returns all leaf-node units of work as
    # NestedUnitOfWork objects.
    require 'enumerator'
    def nested_units_of_work(&block)
      enum = Enumerator.new do |y|
        children.each do |child|
          child.nested_units_of_work do |x|
            y.yield x.nest_under(self)
          end
        end

        units_of_work.each do |x|
          y.yield NestedUnitOfWork.new([self], x)
        end
      end

      if block
        enum.each(&block)
      else
        enum
      end
    end

    def self.root(assertion_context)
      new(nil, assertion_context)
    end

    private

    def memoize(&block)
      called = nil
      ret    = nil

      -> {
        if called
          ret
        else
          called = true
          ret    = block.call
        end
      }
    end
  end

  # Units of work can be nested inside contexts. This is the main object that
  # other components of the system work with.
  NestedUnitOfWork = Struct.new(:parents, :unit_of_work) do
    def block; unit_of_work.block; end
    def name;  unit_of_work.name; end

    def immediate_parent
      parents.last
    end

    def nest_under(parent)
      self.class.new([parent] + parents, unit_of_work)
    end
  end

  # A test failure will be reported as a `Failure`, which includes contextual
  # information about the failure useful for reporting to the user.
  Failure = Struct.new(:unit_of_work, :message, :caller)
end
