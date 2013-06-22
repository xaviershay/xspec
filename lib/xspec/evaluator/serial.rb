# Runs all units of works serially in a loop. It's about as simple an
# evaluator as you can imagine.
module XSpec
  module Evaluator
    class Serial
      def initialize(notifier)
        @notifier = notifier
      end

      def run(context)
        notifier.run_start

        context.nested_units_of_work.each do |x|
          evaluate(x)
        end

        notifier.run_finish
      end

      def evaluate(nested_unit_of_work)
        @current_unit_of_work = nested_unit_of_work
        @current_caller       = caller
        @errors               = []

        instance_exec(&nested_unit_of_work.block)

        notifier.evaluate_finish(nested_unit_of_work, @errors)
      end

      def assert(proposition, msg=nil)
        return if proposition

        self.errors << Error.new(@it, msg, caller - @my_caller)
      end

      protected

      attr_reader :notifier
    end
  end
end
