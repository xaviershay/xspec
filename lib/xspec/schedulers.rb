# # Schedulers

# Schedulers are responsible for collecting all units of work to be run and
# scheduling them.
module XSpec
  module Scheduler
    # The serial scheduler, unsurprisingly, runs all units of works serially in
    # a loop. It is about as simple a scheduler as you can imagine. Parents
    # are responsible for actually executing the work.
    class Serial
      def initialize(opts = {})
        @clock = opts.fetch(:clock, ->{ Time.now.to_f })
      end

      def run(context, config)
        notifier = config.fetch(:notifier)
        notifier.run_start(config)

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

      attr_reader :clock
    end

    class Filter
      def initialize(scheduler:, filter:)
        @scheduler = scheduler
        @filter    = filter
      end

      def run(context, config)
        scheduler.run(FilteredContext.new(context, filter), config)
      end

      FilteredContext = Struct.new(:context, :filter) do
        def nested_units_of_work
          context.nested_units_of_work.select(&filter)
        end
      end

      attr_reader :scheduler, :filter
    end

    DEFAULT = Serial.new
  end
end
