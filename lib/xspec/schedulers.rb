# # Schedulers

# Schedulers are responsible for collecting all units of work to be run and
# scheduling them.
module XSpec
  module Scheduler
    # Most evaluators will use a similar pattern of execution for individual
    # tests, captured here in `TimedExecutor`. Note that parents are
    # responsible for actually executing the work, since they have access to
    # the necessary evaluation context such as method definitions.
    module TimedExecutor
      def initialize(opts = {})
        @clock = opts.fetch(:clock, ->{ Time.now.to_f })
      end

      def evaluate_with_duration(uow, notifier)
        notifier.evaluate_start(uow)

        start_time  = @clock.()
        errors      = uow.immediate_parent.execute(uow)
        finish_time = @clock.()

        result = ExecutedUnitOfWork.new(uow, errors, finish_time - start_time)
        notifier.evaluate_finish(result)
      end
    end

    # The serial scheduler, unsurprisingly, runs all units of works serially in
    # a loop. It is about as simple a scheduler as you can imagine.
    class Serial
      include TimedExecutor

      def run(context, config)
        notifier = config.fetch(:notifier)
        notifier.run_start(config)

        context.nested_units_of_work.each do |x|
          evaluate_with_duration x, notifier
        end

        notifier.run_finish
      end

      protected

      attr_reader :clock
    end


    # Tests can be run in parallel using the threaded scheduler. For fast
    # suites the overhead of creating tests may actually result in slower
    # overall times, but the advantage on longer suites can be substantial.
    #
    # Be careful about using global resources (such as a database) in parallel
    # tests. `Thread.current[:xspec_thread]` contains a sequential numeric
    # identifier for the executing thread, which allows you to set up
    # namespaced resources ahead of time.
    #
    # Note that notifiers that expect a consistent ordering of tests, such as
    # the documentation one, will behave erractically with this scheduler.
    class Threaded
      include TimedExecutor

      def initialize(opts = {})
        super
        @threads = opts.fetch(:threads, 4)
      end

      # Tests are fed to threads via a shared queue. This allows for
      # near-optimal processing of tests, since idle threads can continue to
      # pick up new work.
      def run(context, config)
        notifier = Notifier::Synchronized.new(config.fetch(:notifier))
        notifier.run_start(config)

        queue  = Queue.new
        tracer = Object.new

        threads = @threads.times.map do |n|
          Thread.new do
            Thread.current[:xspec_thread] = n
            loop do
              x = queue.pop
              break if x == tracer
              evaluate_with_duration x, notifier
            end
          end
        end

        context.nested_units_of_work.each do |uow|
          queue << uow
        end

        # A tracer object is flushed through the system to allow for graceful
        # shutdown without having to explicitly kill threads (which would be
        # messy).
        @threads.times do |uow|
          queue << tracer
        end

        threads.each(&:value)

        notifier.run_finish
      end
    end

    # To run a subset of a suite, wrap a scheduler with `Filter`. It takes an
    # lambda that must return true for any particular test to be included.
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

    # `Serial` is the default scheduler since there are caveats when using the
    # others.
    DEFAULT = Serial.new
  end
end
