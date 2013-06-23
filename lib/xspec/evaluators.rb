module XSpec
  module Evaluator
    # Runs all units of works serially in a loop. It's about as simple an
    # evaluator as you can imagine.
    class Serial
      def initialize(opts)
        @notifier          = opts.fetch(:notifier)
        @assertion_context = opts.fetch(:assertion_context)
      end

      def run(context)
        notifier.run_start

        context.nested_units_of_work.each do |x|
          errors = assertion_context.call(x)

          notifier.evaluate_finish(x, errors)
        end

        notifier.run_finish
      end

      protected

      attr_reader :notifier, :assertion_context
    end
  end
end
