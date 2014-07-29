# # XSpec API

# This page documents the public API of
# [XSpec](https://github.com/xaviershay/xspec) through a mix of comments and
# code.
#
# 1. [Basics](#basics)
# 2. [Assertions](#assertions)
# 3. [Doubles](#doubles)
# 4. [Notifiers](#notifiers)
# 5. [Evaluators](#evaluators)
# 6. [Schedulers](#schedulers)
# 7. [Running](#running)
require_relative './support'

# ## Basics
module Basics
  # XSpec tests are specified using the [XSpec DSL](xspec.html#section-3). This is
  # typically added to the global scope, but here we scope it to a module so
  # that elsewhere in the documentation we can include it again with different
  # options.
  #
  # The DSL is customizable. A special documentation context is used in all the
  # examples, see the support file for more details. All configuration options
  # are documented in the "Configuration" section.
  extend XSpec.dsl(
    evaluator: documentation_stack
  )

  # Tests are grouped into contexts, which are created using `describe`. The
  # optional string parameter is used in notifiers to distinguish tests from
  # one another.
  describe 'calculation' do

    # Individual tests are defined using `it`. Like `describe`, it takes an
    # optional string parameter that is used for labeling.
    it 'can add' do
      raise "failed" unless 1 + 1 == 2
    end

    # `expect_to_fail!` is a custom method used only in this documentation to
    # enable demonstrations of failure. It is provided by the documentation
    # stack. (See the support documentation for details.)
    it 'can add' do
      expect_to_fail!

      raise "failed" unless 1 + 1 == 3
    end

    # Methods defined in the context are available in tests. This is often a
    # good technique for decoupling tests from your code, allowing you to
    # define repeated set up and invocation details that are not relevant to
    # the properties being tested.
    def subtract(a, b); a - b end

    it 'can subtract' do
      raise "failed" unless subtract(2, 1) == 1
    end

    # Another common pattern in tests is to set up a memoized variable and
    # refer to it many times both in a single test, and across multiple tests.
    #
    # Each test is run in its own object, so the instance variable here will
    # not persist across tests.
    def input; @input ||= 3 end

    # Since this pattern is so common, a helper method `let` is provided. This
    # invocation is exactly equivalent to the previous definiton of `input`.
    let(:input) { 3 }

    it 'can multiply' do
      raise "failed" unless input * input == 9
    end

    # Contexts can be arbitrarily nested. This is useful for both for
    # organisation and scoping of helper methods, and also grouping in test
    # output.
    describe 'division' do
      # Method definitions from all parents are available in nested contexts.
      # Here the `input` definition defined above is used.
      it 'works' do
        raise "failed" unless input / 3 == 1
      end
    end
  end
end

# ## Assertions
module Assertions
  # Assertions provide a nicer way of handling failures that raising error
  # messages. Like most things in XSpec, they are optional, but it would be
  # rare that you did not use some form of them.
  #
  # The `Simple` evaluator provides basic assertions. While included explicitly
  # here, it is available in the default configuration so can usually be
  # omitted.
  extend XSpec.dsl(
    evaluator: documentation_stack {
      include XSpec::Evaluator::Simple
    }
  )

  describe 'greetings' do
    def greet(x); "hello #{x}" end

    it 'addresses the caller' do
      # `assert` is the basic building block of all assertions. It can be used
      # with a single parameter, in which case it fails the test unless the
      # parameter is truthy (not nil or false).
      assert "hello don" == greet("don")

      # It can also be given a second parameter, which is used instead of the
      # default "assertion failed" failure message.
      assert "hello don" == greet("don"), "greeting did not match expected"

      # A few helpers are provided for common assertions. These are simple
      # wrappers around `assert` that provide a useful failure message.
      assert_equal "hello don", greet("don")
      assert_include "don", greet("don")
    end
  end

  # #### RSpec Integration
  #
  # A built-in context is provided to enable RSpec expectations. (You will need
  # to add `rspec-expecations` as a dependency of your project.)
  module RSpec
    extend XSpec.dsl(
      evaluator: documentation_stack {
        include XSpec::Evaluator::RSpecExpectations
      }
    )

    it 'adds' do
      expect(1 + 1).to eq(2)
    end
  end
end

# ## Doubles
module Doubles
  # Test doubles are "fake" objects that can stand in for collaborators in your
  # system in order to make certain modules easier to unit test. XSpec's
  # implementation shares a philosophy with the
  # [mockito](https://code.google.com/p/mockito/) library, though provides far
  # fewer features.
  #
  # Doubles are the sports car of testing techniques. Extremely powerful, but
  # uncomfortably straightforward to drive into a tree. Only double behaviour
  # that you own, do so sparingly, and you'll stay a contented motorist.
  #
  # Test doubles are available in the default XSpec configuration.
  extend XSpec.dsl(
    evaluator: documentation_stack {
      include XSpec::Evaluator::Doubles
    }
  )

  class Repository
    def store(document)
      _ # implementation not important
    end
  end

  describe 'save' do
    def save(message, repository: Repository.new)
      repository.store(msg: message)
    end

    # Test doubles can be created as copies of existing classes. Use
    # `instance_double` when you are doubling an instance (i.e.
    # `Repository.new`), and `class_double` when doubling class methods.
    let(:repo) { instance_double('Doubles::Repository') }

    # Doubles allow you to selectively verify interactions with them by
    # wrapping them in a call to `verify` then calling the invocation you
    # expected.
    it 'stores a hash document in the repository' do
      save('hello', repository: repo)
      verify(repo).store(msg: 'hello')
    end

    # If a matching method has not been called, the test will fail  This test
    # will fail because the double did not receive a message with "hello".
    it 'stores a hash document in the repository - broken' do
      expect_to_fail!

      save('goodbye', repository: repo)
      verify(repo).store(msg: 'hello')
    end

    # Methods can be stubbed using `stub`. This has the benefit of allowing a
    # return value to be specified. You still may choose to `verify` the
    # invocation as well.
    it 'stores a hash document in the repository' do
      stub(repo).store(msg: 'hello') { true }
      save('hello', repository: repo)
      verify(repo).store(msg: 'hello')
    end

    # By default, doubling classes that do no exist is allowed. It is assumed
    # that the test is being run in isolation so the collaborator, or it has
    # not been implemented yet.
    #
    # If the class does exist, both `verify` and `stub` check invocations
    # against methods that are actually implemented on the doubled class. This
    # test fails because `put` is not a method.
    it 'stores a hash document in the repository' do
      expect_to_fail!
      stub(repo).put(msg: 'hello')
    end

    # If the class does exist, any stub is allowed. It is assumed that
    # this test will be run again in the future either once the class is
    # implemented, or as part of a larger run that loads all collaborators.
    it 'stores a hash document in an alternate repository' do
      alt_repo = class_double('RemoteRepository')
      stub(alt_repo).put(msg: 'hello')
    end

    # #### Strict mode
    module Strict
      # When you know that all collaborators are available, double support can
      # be configured in strict mode.
      #
      # A cute trick is to disable this by default, and only enable it in full
      # test runs. That way individual tests can be executed quickly without
      # loading all dependencies.
      #
      # Strict mode is not enabled in the default XSpec configuration.
      extend XSpec.dsl(
        evaluator: documentation_stack {
          include XSpec::Evaluator::Doubles.with(:strict)
        }
      )

      # In strict mode, any attempt to double a class that does not exist will
      # error.
      it 'stores a hash document in an alternate repository' do
        expect_to_fail!

        class_double('RemoteRepository')
      end
    end
  end
end

# ## Notifiers
# An XSpec notifier is an object that receives callbacks at different stages
# of a test run. Typically this is used to output progress.
#
# While only one notifier can be provided to `XSpec.dsl`, all built-in
# notifiers are composable, meaning they can be combined using `+` to create
# a single notifier that delegates to multiple children. Custom formatters
# can be made composable by include the `Composable` module.
module Notifiers
  # A notifier must implement four methods:
  class DiagnosticNotifier
    include XSpec::Notifier::Composable

    # * `run_start` is called before any tests have been scheduled to run.
    def run_start
      puts "The test run is starting"
    end

    # * `evaluate_start` is called with a `NestedUnitOfWork` just as it is about
    #   to be evaluated.
    def evaluate_start(uow)
      puts "%s is running" % uow.name
    end

    # * `evaluate_finish` is called with an `ExecutedUnitOfWork`, including all
    #   the data from the `NestedUnitOfWork` passed to `evaluate_start`, as
    #   well as any errors and the duration of the evaluation.
    def evaluate_finish(result)
      @failed ||= result.errors.any?

      puts "finished with %i errors in %.3f" % [
        result.errors.length,
        result.duration
      ]
    end

    # * `run_finish` is called after all tests have been executed. The return
    #   value of this method is used to either pass or fail the run.
    def run_finish
      puts "The test run has finished"
      !@failed
    end
  end

  # Notifiers are configured in the `XSpec.dsl` method.
  extend XSpec.dsl(
    notifier: DiagnosticNotifier.new
  )

  # #### Built-in Notifiers
  #
  # * `Character` outputs a single character for each test. A `.` for pass, `F`
  #   for fail, and `E` for an exception. It fails unless all tests are
  #   successful
  # * `ColoredDocumentation` outputs timings and nested descriptions of each
  #   test. It uses ansi coloring to make successful tests green and failed ones
  #   red. It fails unless all tests are successful.
  # * `Documentation` is identical to `ColoredDocumentation` except without the
  #   coloring. Useful if redirecting output to a file.
  # * `FailuresAtEnd` collects all failures and displays details of them (full
  #   test name, failure message, cleaned backtrace) after all tests have been
  #   run. It fails unless all tests are successful.
  # * `TimingsAtEnd` displays a histogram of test durations. It always
  #   succeeds.
  # * `Composite` takes any number of other notifiers and delegates callbacks
  #   to each of them in turn. It fails unless all of those notifiers are
  #   successful. This notifier is created by the `+` operator of `Composable`
  #   notifiers, so is rarely instantiated directly.
  # * `Null` does nothing and is always successful. It is useful as a parent
  #   class for other notifiers, or for testing purposes.
  module BuiltIn
    extend XSpec.dsl(
      notifiers:
        XSpec::Notifier::Character.new +
        XSpec::Notifier::FailuresAtEnd.new
    )
  end
end


# ## Evaluators
#
# `Evalutor` is the module responsible for executing an individual
# test. It will be mixed into a new context object that already has methods
# from the surrounding context defined (including `let` definitions), and
# then have its `call` implementation invoked.
module Evaluators
  module NoTimeEvaluator
    def call(uow)
      instance_exec(&uow.block)
      []
    rescue
      [XSpec::Failure.new(uow, "Failed", caller)]
    end

    def sleep(_)
      _ # noop
    end
  end

  extend XSpec.dsl(
    evaluator: NoTimeEvaluator
  )

  it 'will not execute' do
    sleep 1000
  end
end

# Evaluators are usually composed by creating a _stack_, a module that includes
# other modules.
#
# This works best when individual evaluators call `super` in their `call`
# method and leave `Bottom` to actually execute the test. If you are familiar
# with Rack middleware, this is a very similar concept.
module Stacks
  XE = XSpec::Evaluator

  module Stack
    include XE::Bottom
    include XE::Simple
    include XE::Doubles
    include XE::Top
  end

  # The `stack` method is a shorthand way of creating a stack that sandwiches
  # the given block between the `Top` and `Bottom` evaluators. These two
  # evaluators will be used by virtually every stack.
  #
  # See the [evaluator code documentation](evaluators.html) for
  # more details.
  extend XSpec.dsl(
    evaluator: XE.stack {
      include XE::Simple
      include XE::Doubles
    }
  )
end

# ## Schedulers
#
# A scheduler takes all tests and arranges them to be run. It delegates the
# actual work of running the test to the assertion context, but it is
# responsible for combining the result with timing information and triggering
# the notifier callbacks.

# `Serial` is the only built-in scheduler, and is the default. It runs all
# tests one at a time in the order they were loaded.
module BuiltInScheduler
  extend XSpec.dsl(
    scheduler: XSpec::Scheduler::Serial.new
  )
end

module CustomScheduler
  # This example scheduler runs tests in a random order and does not record
  # durations.
  class ShuffleScheduler
    def run(context, notifier)
      notifier.run_start

      context.nested_units_of_work.sort_by { rand }.each do |uow|
        notifier.evaluate_start(uow)

        errors   = uow.immediate_parent.execute(uow)
        duration = 0
        result   = XSpec::ExecutedUnitOfWork.new(uow, errors, duration)

        notifier.evaluate_finish(result)
      end

      notifier.run_finish
    end
  end

  extend XSpec.dsl(
    scheduler: ShuffleScheduler.new
  )

  it 'executes' do
  end
end

# ## Running
#
# XSpec provides the `xspec` script, that can be used to run XSpec files. It is
# not required, but provides a number of niceties:
# * Adds `spec` and `lib` directories to the load path.
# * Loads all files passed as arguments.
# * Exits non-zero if the run fails.
#
# (`autorun!` provides roughly equivalent behaviour.)
#
# `xspec` requires a global `run!` method, which will be present if you extend
# `XSpec.dsl` into global scope, but in this file we have not done so and need
# to provide our own.
def self.run!(*args)
  exit 1 unless [
    Basics,
    Assertions,
    Assertions::RSpec,
    Doubles,
    Doubles::Strict,
    Notifiers,
    Notifiers::BuiltIn,
    Evaluators,
    Stacks,
    BuiltInScheduler,
    CustomScheduler,
  ].map {|x|
    x.run!(*args)
  }.all?
end
