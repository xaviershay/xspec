# These are the defaults used by `XSpec.dsl`, but feel free to specify your own
# instead. They are set up in such a way that if you can override a component
# down in the bowels without having to provide an entire top level evaluator.
require 'xspec/evaluators'
require 'xspec/assertion_contexts'
require 'xspec/notifiers'

module XSpec
  def add_defaults(options = {})
    # A notifier makes it possible to observe the state of the system, be that
    # progress or details of failing tests.
    options[:notifier]          ||= Notifier::Character.new +
                                    Notifier::FailuresAtEnd.new

    # A unit of work will run as an instance method on the context it is
    # defined in, but in addition an assertion context will be added as well.
    # This is a module that is included as the final step in constructing a
    # context. Allows for different matchers and expectation frameworks to be
    # used.
    options[:assertion_context] ||= AssertionContext::Simple

    # An evaluator is responsible for scheduling units of work and handing them
    # off to the assertion context. Any logic regarding threads, remote
    # execution or the like belongs in an evaluator.
    options[:evaluator]         ||= Evaluator::Serial.new(options)
    options
  end
  module_function :add_defaults
end
