# XSpec data structures are very dumb. They:
#
# * Only contain iteration and creation logic.
# * Do not store recursive references ("everything flows downhill").
module XSpec
  # A unit of work, usually created via `Describe#it`, is a labeled code block
  # that expresses an assertion about a property of the system under test. They
  # are indivisible.
  #
  # These are run inside an `XSpec::Evaluator`.
  UnitOfWork = Struct.new(:name, :block)

  # A context is a recursively nested structure, usually created with the
  # `describe` DSL method, that contains other contexts and units of work.
  # They are optional to use explicitly - extending `Xspec.dsl` will create
  # an implicit one - but are useful for organising your tests.
  require 'xspec/dsl'
  class Context

    def __xspec_context; self; end
    include ::XSpec::DSL

    attr_reader :name, :children, :units_of_work

    def initialize(name)
      @children      = []
      @units_of_work = []
      @name          = name
    end

    def add_child_context(name, opts = {}, &block)
      x = Context.new(name)
      x.instance_exec(&block)
      self.children << x
    end

    def add_unit_of_work(name, opts = {}, &block)
      self.units_of_work << UnitOfWork.new(name, block)
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

  # Marker object for the root of the context tree. For most purposes it
  # behaves exactly like a normal `Context`.
  class RootContext < Context
    def initialize
      super('')
    end
  end

  # Units of work can be nested inside contexts. This is the main object that
  # other components of the system work with.
  NestedUnitOfWork = Struct.new(:parents, :unit_of_work) do
    def block; unit_of_work.block; end
    def name;  unit_of_work.name; end

    def nest_under(parent)
      self.class.new([parent] + parents, unit_of_work)
    end
  end

  # A test failure will be reported as a `Failure`, which includes contextual
  # information about the failure useful for reporting to the user.
  Failure = Struct.new(:unit_of_work, :msg, :caller) do
    def message
      msg || "assertion failed"
    end
  end
end
