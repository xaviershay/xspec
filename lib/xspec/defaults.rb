# # Defaults

# These are the defaults used by `XSpec.dsl`, but feel free to specify your own
# instead. They are set up in such a way that if you can override a component
# down in the bowels without having to provide an entire top level scheduler.
require 'xspec/schedulers'
require 'xspec/evaluators'
require 'xspec/notifiers'

require 'digest/sha1'

module XSpec
  def default_short_id(uow)
    length  = 3
    base    = 32
    digest  = Digest::SHA1.hexdigest(uow.full_name).hex
    bottom  = base ** (length-1)
    top     = base ** length
    shifted = digest % (top - bottom) + bottom

    shifted.to_s(base)
  end
  module_function :default_short_id

  def add_defaults(options = {})
    # A notifier makes it possible to observe the state of the system, be that
    # progress or details of failing tests.
    options[:notifier] ||= XSpec::Notifier::DEFAULT

    # A unit of work will run as an instance method on the context it is
    # defined in, but in addition an assertion context will be added as well.
    # This is a module that is included as the final step in constructing a
    # context. Allows for different matchers and expectation frameworks to be
    # used.
    options[:evaluator] ||= Evaluator::DEFAULT

    options[:short_id] ||= XSpec.method(:default_short_id)


    # An scheduler is responsible for scheduling units of work and handing them
    # off to the assertion context. Any logic regarding threads, remote
    # execution or the like belongs in a scheduler.
    options[:scheduler]         ||= Scheduler::DEFAULT
    options
  end
  module_function :add_defaults
end
