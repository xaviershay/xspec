require 'simplecov'
SimpleCov.start

require 'xspec'

extend XSpec.dsl(
  notifier: XSpec::Notifier::ColoredDocumentation.new +
            XSpec::Notifier::TimingsAtEnd.new +
            XSpec::Notifier::FailuresAtEnd.new
)

def assert_errors_from_run(context, expected_error_messages)
  context.run!

  notifier = context.__xspec_config.fetch(:notifier)
  assert_equal expected_error_messages, notifier.errors.flatten.map(&:message)
end

def with_dsl(opts, &block)
  c = Class.new do
    notifier = Class.new(XSpec::Notifier::Null) do
      attr_reader :errors

      def initialize
        @errors = []
      end

      def evaluate_finish(result)
        @errors << result.errors
      end
    end.new

    extend XSpec.dsl({notifier: notifier}.merge(opts))

    instance_exec(&block)
  end
end
