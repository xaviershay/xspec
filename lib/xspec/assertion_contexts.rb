# Assertion contexts have a single API. They must respond to `call` sent with
# the unit of work to be executed, and return an array of `Failure` objects.
module XSpec
  module AssertionContext
    module Simple
      class AssertionFailed < RuntimeError
        attr_reader :message, :backtrace

        def initialize(message, backtrace)
          @message   = message
          @backtrace = backtrace
        end
      end

      def call(unit_of_work)
        instance_exec(&unit_of_work.block)
        []
      rescue AssertionFailed => e
        [Failure.new(unit_of_work, e.message, e.backtrace)]
      rescue => e
        [CodeException.new(unit_of_work, e.message, e.backtrace)]
      end

      def assert(proposition, message=nil)
        message ||= 'assertion failed'

        raise AssertionFailed.new(message, caller) unless proposition
      end
    end

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

        context.mixin(RSpec::Matchers)
      end

      def call(unit_of_work)
        instance_exec(&unit_of_work.block)
        []
      rescue RSpec::Expectations::ExpectationNotMetError => e
        [Failure.new(unit_of_work, e.message, e.backtrace)]
      end

      def expect(*target, &target_block)
        target << target_block if block_given?
        unless target.size == 1
          raise ArgumentError, "Pass an argument or a block, not both."
        end
        ::RSpec::Expectations::ExpectationTarget.new(target.first)
      end
    end
  end
end
