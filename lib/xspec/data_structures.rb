# # Data Structures

# XSpec data structures are very dumb. They:
#
# * Only contain iteration, property, and creation logic.
# * Do not store recursive references ("everything flows downhill").
module XSpec
  # A unit of work, usually created by the `it` DSL method, is a labeled,
  # indivisible code block that expresses an assertion about a property of the
  # system under test. They are run by a scheduler.
  UnitOfWork = Struct.new(:name, :block)


  # A context is a recursively nested structure, usually created with the
  # `describe` DSL method, that contains other contexts and units of work. Most
  # of the logic for a context happens at the class level rather than instance,
  # which is unusual but required for method inheritance to work correctly. It
  # currently violates the logic rule specified above, more work is required to
  # decouple it.
  require 'xspec/dsl'
  class Context
    class << self
      attr_reader :name, :children, :units_of_work, :evaluator

      # A context includes the same DSL methods as the root level module, which
      # enables the recursive creation.
      def __xspec_context; self; end
      include ::XSpec::DSL

      # Each nested context creates a new class that inherits from the parent.
      # Methods can be added to this class as per normal, and are correctly
      # inherited by children. When it comes time to run tests, the scheduler
      # will create a new instance of the context (a class) for each test,
      # making the defined methods available and also ensuring that there is no
      # state pollution between tests.
      def make(name, evaluator, &block)
        x = Class.new(self)
        x.initialize!(name, evaluator)
        x.class_eval(&block) if block
        x.apply_evaluator!
        x
      end

      # A class cannot have an implicit initializer, but some variable
      # inititialization is required so the `initialize!` method is called
      # explicitly when ever a dynamic subclass is created.
      def initialize!(name, evaluator)
        @children          = []
        @units_of_work     = []
        @name              = name
        @evaluator = evaluator
      end

      # The assertion context should be applied after the user has had a chance
      # to add their own methods. It needs to be last so that users can't
      # clobber the assertion methods.
      def apply_evaluator!
        include(evaluator)
      end

      # Executing a unit of work creates a new instance and hands it off to the
      # `call` method, which is defined by whichever assertion context is being
      # used. By creating a new instance everytime, no state is preserved
      # between executions.
      def execute(unit_of_work)
        new.call(unit_of_work)
      end

      # The root context is nothing special, and behaves the same as all the
      # others.
      def root(evaluator)
        make(nil, evaluator)
      end

      # Child contexts and units of work are typically added by the `describe`
      # and `it` DSL methods respectively.
      def add_child_context(name = nil, opts = {}, &block)
        self.children << make(name, evaluator, &block)
      end

      def add_unit_of_work(name = nil, opts = {}, &block)
        self.units_of_work << UnitOfWork.new(name, block)
      end

      # A shared context is a floating context that isn't part of any context
      # heirachy, so its units of work will not be visible to the root node. It
      # can be brought into any point in the heirachy using `copy_into_tree`
      # (aliased as `include_context` in the DSL), and this can be done
      # multiple times, which allows definitions to be reused.
      #
      # This is leaky abstraction, since only units of work are copied from
      # shared contexts. Methods and child contexts are ignored.
      def create_shared_context(&block)
        make(nil, evaluator, &block)
      end

      def copy_into_tree(source_context)
        target_context = make(
          source_context.name,
          source_context.evaluator
        )
        source_context.nested_units_of_work.each do |x|
          target_context.units_of_work << x.unit_of_work
        end
        self.children << target_context
        target_context
      end

      # The most convenient way to access all units of work is this recursive
      # iteration that returns all leaf-nodes as `NestedUnitOfWork` objects.
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

      # Values of memoized methods are remembered only for the duration of a
      # single unit of work. These are typically created using the `let` DSL
      # method.
      def add_memoized_method(name, &block)
        define_method(name) do
          memoized[block] ||= instance_eval(&block)
        end
      end

      # Dynamically generated classes are hard to identify in object graphs, so
      # it is helpful for debugging to set an explicit name.
      def to_s
        "Context:'#{name}'"
      end
    end

    def memoized
      @memoized ||= {}
    end
  end

  # Units of work can be nested inside contexts. This is the main object that
  # other components of the system work with.
  NestedUnitOfWork = Struct.new(:parents, :unit_of_work) do
    def block; unit_of_work.block; end
    def name;  unit_of_work.name; end

    def full_name
      (parents + [self]).map(&:name).compact.join(' ')
    end

    def immediate_parent
      parents.last
    end

    def nest_under(parent)
      self.class.new([parent] + parents, unit_of_work)
    end
  end

  # The result of executing a unit of work, including timing information. This
  # is passed to notifiers for display or other processing.
  ExecutedUnitOfWork = Struct.new(:nested_unit_of_work, :errors, :duration) do
    def name; nested_unit_of_work.name end
    def parents; nested_unit_of_work.parents end
    def full_name; nested_unit_of_work.full_name end
  end

  # A test failure will be reported as a `Failure`, which includes contextual
  # information about the failure useful for reporting to the user.
  Failure = Struct.new(:unit_of_work, :message, :caller)

  # An exception is mostly handled the same way as a failure.
  CodeException = Class.new(Failure)
end
