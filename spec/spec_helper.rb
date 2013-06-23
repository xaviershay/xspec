require 'xspec/autorun'
require 'xspec/notifier/null'

def assert_errors_from_run(context, expected_error_messages)
  evaluator = context.__xspec_opts.fetch(:evaluator)
  notifier  = context.__xspec_opts.fetch(:notifier)

  evaluator.run(context.__xspec_context)

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
