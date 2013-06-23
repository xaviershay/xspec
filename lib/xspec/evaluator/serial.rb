# Runs all units of works serially in a loop. It's about as simple an
# evaluator as you can imagine.
module XSpec
  module Evaluator
    class Serial
      def initialize(opts)
        @notifier          = opts.fetch(:notifier)
        @assertion_context = opts.fetch(:assertion_context)
      end

      def run(context)
        notifier.run_start

        context.nested_units_of_work.each do |x|
          evaluate(x)
        end

        notifier.run_finish
      end

      def evaluate(nested_unit_of_work)
        errors = assertion_context.(nested_unit_of_work)

        notifier.evaluate_finish(nested_unit_of_work, errors)
      end

      protected

      attr_reader :notifier, :assertion_context
    end
  end
end
