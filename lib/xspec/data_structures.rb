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
  # `describe` DSL method, that contains other contexts and units of work. Most
  # of the logic for a context happens at the class level rather than instance,
  # which is unusual but required for method inheritance to work correctly.
  #
  # Each nested context creates a new class that inherits from the parent.
  # Methods can be added to this class as per normal, and are correctly
  # inherited by children. When it comes time to run tests, the evaluator will
  # create a new instance of the context (a class) for each test, making the
  # defined methods available and also ensuring that there is no state
  # pollution between tests.
  #
  # An assertion context is always included as the final mixin to a context
  # class, making assertion methods available as instance methods to the units
  # of work.
  require 'xspec/dsl'
  class Context
    class << self
      def __xspec_context; self; end
      include ::XSpec::DSL

      attr_accessor :name, :children
      attr_reader :units_of_work, :assertion_context

      # Creating a new child context inherits any methods defined on the parent
      # and its assertion context, which is applied after user-defined methods
      # (i.e. the body of the describe block) have been added.
      def make(name, assertion_context, &block)
        x = Class.new(self)
        x.initialize!(name, assertion_context)
        x.class_eval(&block) if block
        x.apply_assertion_context!
        x
      end

      def root(assertion_context)
        make(nil, assertion_context)
      end

      # A class cannot have an implicit initializer, but some variable
      # inititialization is required so this method is called explicitly when
      # ever a dynamic subclass is created.
      def initialize!(name, assertion_context)
        @children          = []
        @units_of_work     = []
        @name              = name
        @assertion_context = assertion_context
      end

      # The assertion context should be applied after the user has had a chance
      # to add their own methods. It needs to be last so that users can't
      # clobber the assertion methods.
      def apply_assertion_context!
        mixin(assertion_context)
      end

      # `include` is normally private, but it is useful to allow other classes
      # and modules to include additional behaviour (such as assertion
      # contexts).
      def mixin(mod)
        include(mod)
      end

      def add_child_context(name = nil, opts = {}, &block)
        self.children << make(name, assertion_context, &block)
      end

      def add_unit_of_work(name = nil, opts = {}, &block)
        self.units_of_work << UnitOfWork.new(name, block)
      end

      # Values of memoized methods are remembered only for the duration of a
      # single unit of work. These are typically creates using the `let` DSL
      # method.
      def add_memoized_method(name, &block)
        define_method(name) do
          memoized[block] ||= instance_eval(&block)
        end
      end

      def to_s
        "Context:'#{name}'"
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
    end

    attr_accessor :memoized

    def initialize
      @memoized = {}
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
