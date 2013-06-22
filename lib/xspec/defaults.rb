# These are the defaults used by `XSpec.dsl`, but feel free to specify your own
# instead. They are set up in such a way that if you can override a component
# down in the bowels without having to provide an entire top level evaluator.
require 'xspec/evaluator/serial'
require 'xspec/notifier/character'
module XSpec
  def add_defaults(options = {})
    # A notifier makes it possible to observe the state of the system, be that
    # progress or details of failing tests.
    options[:notifier]  ||= XSpec::Notifier::Character.new

    # An evaluator is responsible for scheduling and executing units of work.
    # Any logic regarding threads, remote execution or the like belongs in an
    # evaluator.
    options[:evaluator] ||= XSpec::Evaluator::Serial.new(options.fetch(:notifier))
    options
  end
  module_function :add_defaults
end
