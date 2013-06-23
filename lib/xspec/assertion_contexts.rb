# Assertion contexts have a single API. They must respond to `call` sent with
# the unit of work to be executed, and return an array of `Failure` objects.
# Thread-safety is required.
module XSpec
  module AssertionContext
    class Simple
      class AssertionFailed < RuntimeError; end

      def call(unit_of_work)
        instance_exec(&unit_of_work.block)
        []
      rescue AssertionFailed => e
        [Failure.new(unit_of_work, e.message, caller)]
      end

      def assert(proposition, message=nil)
        raise AssertionFailed, message unless proposition
      end
    end

    class RSpecExpectations
      def initialize
        begin
          require 'rspec/expectations'
          require 'rspec/matchers'
        rescue LoadError
          raise "RSpec is not available, cannot use RSpec adapter."
        end

        extend RSpec::Matchers
      end

      def call(unit_of_work)
        instance_exec(&unit_of_work.block)
        []
      rescue RSpec::Expectations::ExpectationNotMetError => e
        [Failure.new(unit_of_work, e.message, caller)]
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
