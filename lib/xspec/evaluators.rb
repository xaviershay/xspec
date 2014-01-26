# Evaluators are responsible for collecting all units of work to be run and
# scheduling them.
module XSpec
  module Evaluator
    # The serial evaluator, unsurprisingly, runs all units of works serially in
    # a loop. It's about as simple an evaluator as you can imagine.
    class Serial
      def initialize(opts)
        @notifier = opts.fetch(:notifier)
      end

      def run(context)
        notifier.run_start

        context.nested_units_of_work.each do |x|
          errors = x.immediate_parent.execute(x)

          notifier.evaluate_finish(x, errors)
        end

        notifier.run_finish
      end

      protected

      attr_reader :notifier
    end
  end
end
