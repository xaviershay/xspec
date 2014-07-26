require 'spec_helper'
require 'stringio'

ComposableNotifier = shared_context do
  it 'can be composed with itself' do
    assert (notifier + notifier).run_finish
  end
end

describe 'failures at end notifier' do
  let(:out)      { StringIO.new }
  let(:notifier) { XSpec::Notifier::FailuresAtEnd.new(out) }

  it 'returns true when no errors are observed' do
    assert notifier.run_finish
  end

  it 'includes full name in failure' do
    failure = XSpec::Failure.new(
      make_nested_test([nil, 'a', nil, 'b'], 'c'),
      "failed",
      []
    )
    notifier.evaluate_finish(make_executed_test errors: [failure])

    assert !notifier.run_finish
    assert_include "a b c:\n  failed", out.string
  end

  it 'cleans lib entries out of backtrace' do
    failure = XSpec::Failure.new(
      make_nested_test([nil, 'a', nil, 'b'], 'c'),
      "failed",
      [File.expand_path('../../../lib', __FILE__) + '/bogus.rb']
    )
    notifier.evaluate_finish(make_executed_test errors: [failure])

    assert !notifier.run_finish
    assert !out.string.include?('bogus.rb')
  end

  include_context ComposableNotifier
end

describe 'character notifier' do
  let(:notifier) { XSpec::Notifier::Character.new(out) }
  let(:out)      { StringIO.new }

  it 'outputs a . for every successful test' do
    notifier.evaluate_finish(make_executed_test)
    notifier.evaluate_finish(make_executed_test)

    assert notifier.run_finish
    assert out.string == "..\n"
  end

  it 'outputs a F for every failed test' do
    notifier.evaluate_finish(make_executed_test errors: [make_failure])

    assert !notifier.run_finish
    assert out.string == "F\n"
  end

  it 'outputs an E for every errored test' do
    notifier.evaluate_finish(make_executed_test errors: [make_error])

    assert !notifier.run_finish
    assert out.string == "E\n"
  end

  include_context ComposableNotifier
end

describe 'documentation notifier' do
  let(:notifier) { XSpec::Notifier::Documentation.new(out) }
  let(:out)      { StringIO.new }

  def evaluate_finish(args)
    notifier.evaluate_finish(make_executed_test args)
    out.string
  end

  it 'outputs each context with a header and individual tests' do
    assert_equal "\na\n  0.001s b\n",
      evaluate_finish(parents: ['a'], name: 'b')
  end

  it 'adds an indent for each nested context' do
    assert_equal "\na\n  b\n    0.001s c\n",
      evaluate_finish(parents: ['a', 'b'], name: 'c')
  end

  it 'does not repeat top level parents for multiple nested contexts' do
    evaluate_finish(parents: ['a', 'b'], name: 'c')
    evaluate_finish(parents: ['a', 'd'], name: 'e')

    assert_equal "\na\n  b\n    0.001s c\n\n  d\n    0.001s e\n", out.string
  end

  it 'ignores contexts with no name' do
    assert_equal "\na\n  0.001s b\n",
      evaluate_finish(parents: [nil, 'a', nil], name: 'b')
  end

  it 'suffixes FAILED to tests when they fail' do

    assert_include "a - FAILED",
      evaluate_finish(errors: [make_failure], name: 'a')
  end

  it 'outputs FAILED for unnamed tests when they fail' do
    assert_include "FAILED", evaluate_finish(name: nil, errors: [make_failure])
  end

  it 'outputs FAILED for unnamed tests when they error' do
    assert_include "FAILED", evaluate_finish(errors: [make_error])
  end

  include_context ComposableNotifier
end

describe 'colored documentation notifier' do
  let(:notifier) { XSpec::Notifier::ColoredDocumentation.new(out) }
  let(:out)      { StringIO.new }

  it 'colors successful tests green' do
    notifier.evaluate_finish(make_executed_test errors: [])

    assert_include "\e[32m\e[0m\n", out.string
  end

  it 'colors failed and errored tests red' do
    notifier.evaluate_finish(make_executed_test errors: [make_failure])

    assert_include "\e[31mFAILED\e[0m", out.string
  end

  include_context ComposableNotifier
end

describe 'composable notifier' do
  let(:notifier) { XSpec::Notifier::Composite.new }

  include_context ComposableNotifier
end

describe 'null notifier' do
  let(:notifier) { XSpec::Notifier::Null.new }

  it 'always returns true' do
    assert notifier.run_finish
  end

  it_behaves_like_a ComposableNotifier
end

describe 'timings at end' do
  let(:notifier) { XSpec::Notifier::TimingsAtEnd.new(out: out) }

  it 'always returns true' do
    assert notifier.run_finish
  end

  include_context ComposableNotifier
end

def make_nested_test(parent_names = [], work_name = nil)
  XSpec::NestedUnitOfWork.new(
    parent_names.map {|name| XSpec::Context.make(name, Module.new) },
    XSpec::UnitOfWork.new(work_name, ->{})
  )
end

def make_executed_test(parents: [], errors: [], duration: 0.001, name: nil)
  XSpec::ExecutedUnitOfWork.new(
    XSpec::NestedUnitOfWork.new(
      parents.map {|name| XSpec::Context.make(name, Module.new) },
      XSpec::UnitOfWork.new(name, ->{})
    ),
    errors,
    duration
  )
end

def make_failure
  failure = XSpec::Failure.new(
    make_nested_test([], 'failure'),
    "failed",
    []
  )
end

def make_error
  failure = XSpec::CodeException.new(
    make_nested_test([], 'failure'),
    "failed",
    []
  )
end
