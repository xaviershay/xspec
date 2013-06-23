require 'xspec/autorun'

def assert_errors_from_run(context, expected_error_messages)
  context.run!

  notifier = context.__xspec_opts.fetch(:notifier)
  assert notifier.errors.flatten.map(&:message) == expected_error_messages
end

def with_dsl(opts, &block)
  c = Class.new do
    notifier = Class.new(XSpec::Notifier::Null) do
      attr_reader :errors

      def initialize
        @errors = []
      end

      def evaluate_finish(unit_of_work, errors)
        @errors << errors
      end
    end.new

    extend XSpec.dsl(opts.merge(notifier: notifier))

    instance_exec(&block)
  end
end
