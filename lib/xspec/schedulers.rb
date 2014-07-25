# # Schedulers

# Schedulers are responsible for collecting all units of work to be run and
# scheduling them.
module XSpec
  module Scheduler
    # The serial scheduler, unsurprisingly, runs all units of works serially in
    # a loop. It is about as simple a scheduler as you can imagine. Parents
    # are responsible for actually executing the work.
    class Serial
      def initialize(opts)
        @notifier = opts.fetch(:notifier)
        @clock    = opts.fetch(:clock, ->{ Time.now.to_f })
      end

      # TODO: Move notifier here, pass it in from framework.
      def run(context)
        notifier.run_start

        context.nested_units_of_work.each do |x|
          notifier.evaluate_start(x)

          start_time  = clock.()
          errors      = x.immediate_parent.execute(x)
          finish_time = clock.()

          result = ExecutedUnitOfWork.new(x, errors, finish_time - start_time)
          notifier.evaluate_finish(result)
        end

        notifier.run_finish
      end

      protected

      attr_reader :notifier, :clock
    end

    DEFAULT = Serial
  end
end
