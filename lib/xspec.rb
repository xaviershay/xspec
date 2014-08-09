# # XSpec

# Hello and welcome to XSpec!
#
# XSpec is an rspec-inspired testing library that is designed to be highly
# modular and easy to extend. Let's dive right in.
module XSpec
  # The DSL is the core of XSpec. It dynamically generates a module that can be
  # mixed into which ever context you choose (using `extend`), be that the
  # top-level namespace or a specific class.
  #
  # This enables different options to be specified per DSL, which is at the
  # heart of XSpec's modularity. It is easy to change every component to your
  # liking.
  def dsl(options = {})
    options = XSpec.add_defaults(options)

    Module.new do
      # Each DSL provides a standard set of methods provided by the [DSL
      # module](dsl.html).
      include DSL

      # In addition, each DSL has its own independent context, which is
      # described in detail in the
      # [`data_structures.rb`](data_structures.html).
      def __xspec_context
        evaluator = __xspec_opts.fetch(:evaluator)
        @__xspec_context ||= XSpec::Context.root(evaluator)
      end

      # Some meta-magic is needed to enable the options from local scope above
      # to be available inside the module.
      define_method(:__xspec_opts) { options }

      # `run!` is where the magic happens. Typically called at the end of a
      # file (or by `autorun!`), this method takes all the data that was
      # accumulated by the DSL methods above and runs it through the scheduler.
      #
      # It takes an optional parameter that can be used to override any options
      # set in the initial `XSpec.dsl` call.
      def run!(overrides = {})
        config = __xspec_opts.merge(overrides)
        scheduler = config.fetch(:scheduler)

        scheduler.run(__xspec_context, config)
      end

      # It is often convenient to trigger a run after all files have been
      # processed, which is what `autorun!` sets up for you. Requiring
      # `xspec/autorun` does this automatically for you.
      def autorun!
        at_exit do
          exit 1 unless run!
        end
      end
    end
  end
  module_function :dsl
end

# Understanding the [data structures](data_structures.html) used by XSpec will
# assist you in understanding the behavoural components such as the scheduler
# and notifier. Read it next.
require 'xspec/data_structures'

# To further explore the code base, dive into the [defaults
# file](defaults.html), which describes the different sub-components of XSpec
# that you can use or customize.
require 'xspec/defaults'

require 'xspec/dsl'
