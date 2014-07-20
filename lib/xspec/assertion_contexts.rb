# # Assertion Contexts

# Assertion contexts are composed together into a context stack. The final
# stack has a single API method `call`, which is sent the unit of work to be
# executed and must return an array of `Failure` objects. It should not allow
# code-level exceptions to be raised, though should not block system exceptions
# (`SignalException`, `NoMemoryError`, etc).
module XSpec
  module AssertionContext
    # A stack is typically book-ended by the top and bottom contexts, so this
    # helper is the most commond way to build up a custom stack.
    def self.stack(&block)
      Module.new do
        include Bottom
        instance_exec &block
        include Top
      end
    end

    # The bottom context executes the unit of work, with no error handling or
    # extra behaviour. By separating this, all other contexts layered on top of
    # this one can just call `super`, making them easy to compose.
    module Bottom
      def call(unit_of_work)
        instance_exec(&unit_of_work.block)
        []
      end
    end

    # The top should be included as the final module in a context stack. It is
    # a catch all to make sure all standard exceptions have been handled and
    # do not leak outside the stack.
    module Top
      def call(unit_of_work)
        super
      rescue => e
        [CodeException.new(unit_of_work, e.message, e.backtrace)]
      end
    end

    # ### Simple Assertions
    #
    # This simple context provides very straight-forward assertion methods.
    module Simple
      class AssertionFailed < RuntimeError
        attr_reader :message, :backtrace

        def initialize(message, backtrace)
          @message   = message
          @backtrace = backtrace
        end
      end

      def call(unit_of_work)
        super
      rescue AssertionFailed => e
        [Failure.new(unit_of_work, e.message, e.backtrace)]
      end

      def assert(proposition, message=nil)
        unless proposition
          message ||= 'assertion failed'

          _raise message
        end
      end

      def assert_equal(expected, actual)
        unless expected == actual
          message ||= <<-EOS.chomp
want: #{expected.inspect}
 got: #{actual.inspect}
EOS

          _raise message
        end
      end

      def assert_include(expected, output)
        assert output.include?(expected),
          "#{expected.inspect} not present in: #{output.inspect}"
      end

      def fail(message = nil)
        message ||= 'failed'

        _raise message
      end

      private

      def _raise(message)
        raise AssertionFailed.new(message, caller)
      end
    end

    # ### Doubles
    #
    # The doubles module provides test doubles that can be used in-place of
    # real objects.
    module Doubles
      DoubleFailure = Class.new(RuntimeError)

      def call(unit_of_work)
        super
      rescue DoubleFailure => e
        [Failure.new(unit_of_work, e.message, e.backtrace)]
      end

      # It can be configured with a few options:
      #
      # * `auto_verify` calls `assert_exhausted` on all created doubles after a
      # unit of work executes successfully to ensure that all expectations that
      # were set were actually called.
      # * `strict` forbids doubling of classes that have not been loaded. This
      # should generally be enabled when doing a full spec run, and disabled
      # when running specs in isolation.
      #
      # The `with` method returns a module that can be included in a stack.
      def self.with(*opts)
        modules = [self] + opts.map {|x| {
          auto_verify: AutoVerify,
          strict:      Strict
        }.fetch(x) }


        Module.new do
          modules.each do |m|
            include m
          end
        end
      end

      # An instance double stands in for an instance of the given class
      # reference, given as a string. The class does not need to be loaded, but
      # if it is then only public instance methods defined on the class are
      # able to be expected.
      def instance_double(klass)
        _double(klass, InstanceReference)
      end

      # Simarly, a class double validates that class responds to all expected
      # methods, if that class has been loaded.
      def class_double(klass)
        _double(klass, ClassReference)
      end

      # If the doubled class has not been loaded, a null object reference is
      # used that allows expecting of all methods.
      def _double(klass, type)
        ref = if self.class.const_defined?(klass)
          type.new(self.class.const_get(klass))
        else
          StringReference.new(klass)
        end

        Double.new(ref)
      end

      # To set up an expectation on a double, call the expected method an
      # arguments on the proxy object returned by `expect`. If a return value
      # is desired, it can be supplied as a block, for example:
      # `expect(double).some_method(1, 2) { "return value" }`
      def expect(obj)
        Recorder.new(obj)
      end

      class Recorder
        def initialize(double)
          @double = double
        end

        def method_missing(*args, &ret)
          @double._expect(args, &(ret || ->{}))
        end
      end

      # Since the double object inherits from `BasicObject`, virtually every
      # method call will be routed through `method_missing`. From there, the
      # call can be checked against the expectations that were setup at the
      # beginning of a spec.
      class Double < BasicObject
        def initialize(klass)
          @klass    = klass
          @expected = []
        end

        def method_missing(*actual_args)
          i = @expected.find_index {|expected_args, ret|
            expected_args == actual_args
          }

          if i
            @expected.delete_at(i)[1].call
          else
            name, rest = *actual_args
            ::Kernel.raise DoubleFailure, "Unexpectedly received: %s(%s)" % [
              name,
              [*rest].map(&:inspect).join(", ")
            ]
          end
        end

        # The two methods needed on this object to set it up and verify it are
        # prefixed by `_` to try to ensure they don't clash with any method
        # expectations. While not fail-safe, users should only be using
        # expectations for a public API, and `_` is traditionally only used
        # for private methods (if at all).
        def _expect(args, &ret)
          @klass.validate_call! args

          @expected << [args, ret]
        end

        def _verify
          return if @expected.empty?

          ::Kernel.raise DoubleFailure, "%s double did not receive:\n%s" % [
            @klass.to_s,
            @expected.map {|(name, *args), _|
              "  %s(%s)" % [name, args.map(&:inspect).join(", ")]
            }.join("\n")
          ]
        end
      end

      # A reference can be thought of as a "backing object" for a double. It
      # provides an API to validate that a method being expected actually
      # exists - the implementation is different for the different types of
      # doubles.
      class Reference
        def initialize(klass)
          @klass = klass
        end

        def validate_call!(args)
        end

        def to_s
          @klass.to_s
        end
      end

      # A string reference is the "null object" of references, allowing all
      # methods to be expected. It is used when nothing is known about the
      # referenced class (such as when it has not been loaded).
      class StringReference < Reference
      end

      # Class and Instance references are backed by loaded classes, and
      # restrict the messages that can be expected on a double.
      class ClassReference < Reference
        def validate_call!(args)
          name, rest = *args

          unless @klass.respond_to?(name)
            raise DoubleFailure,
              "#{@klass}.#{name} is unimplemented or not public"
          end
        end
      end

      class InstanceReference < Reference
        def validate_call!(args)
          name, rest = *args

          unless @klass.public_instance_methods.include?(name)
            raise DoubleFailure,
              "#{@klass}##{name} is unimplemented or not public"
          end
        end
      end

      # The `:strict` option mixes in this `Strict` module, which raises rather
      # than create `StringReference`s for unknown classes.
      module Strict
        def _double(klass, type)
          ref = if self.class.const_defined?(klass)
            type.new(self.class.const_get(klass))
          else
            raise DoubleFailure, "#{klass} is not a valid class name"
          end

          super
        end
      end

      # An assertion is provided to validate that all expected methods were
      # called on a double.
      def assert_exhausted(obj)
        obj._verify
      end

      # Most of the time, `assert_exhausted` will not be called directly, since
      # the `:auto_verify` option can be used to call it by default on all
      # doubles. That option mixes in this `AutoVerify` module to augment
      # methods necessary for this behaviour.
      module AutoVerify
        def initialize
          @doubles = []
        end

        def call(unit_of_work)
          result = super

          if result.empty?
            @doubles.each do |double|
              assert_exhausted double
            end
          end

          result
        rescue DoubleFailure => e
          [Failure.new(unit_of_work, e.message, e.backtrace)]
        end

        def class_double(klass)
          x = super
          @doubles << x
          x
        end

        def instance_double(klass)
          x = super
          @doubles << x
          x
        end
      end
    end

    # ### RSpec Integration
    #
    # This RSpec adapter shows two useful techniques: dynamic library loading
    # which removes RSpec as a direct dependency, and use of the `mixin`
    # method to further extend the target context.
    module RSpecExpectations
      def self.included(context)
        begin
          require 'rspec/expectations'
          require 'rspec/matchers'
        rescue LoadError
          raise "RSpec is not available, cannot use RSpec assertion context."
        end

        context.include(RSpec::Matchers)
      end

      def call(unit_of_work)
        super
      rescue RSpec::Expectations::ExpectationNotMetError => e
        [Failure.new(unit_of_work, e.message, e.backtrace)]
      end
    end

    DEFAULT = stack do
      include Simple
      include Doubles.with(:auto_verify)
    end
  end
end
