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
    notifier.evaluate_finish(nil, [failure])

    assert !notifier.run_finish
    assert out.string.include?('a b c: failed')
  end

  it 'cleans lib entries out of backtrace' do
    failure = XSpec::Failure.new(
      make_nested_test([nil, 'a', nil, 'b'], 'c'),
      "failed",
      [File.expand_path('../../lib', __FILE__) + '/bogus.rb']
    )
    notifier.evaluate_finish(nil, [failure])

    assert !notifier.run_finish
    assert !out.string.include?('bogus.rb')
  end

  it_behaves_like_a ComposableNotifier
end

describe 'character notifier' do
  let(:notifier) { XSpec::Notifier::Character.new(out) }
  let(:out)      { StringIO.new }

  it 'outputs a . for every successful test' do
    notifier.evaluate_finish(nil, [])
    notifier.evaluate_finish(nil, [])

    assert notifier.run_finish
    assert out.string == "..\n"
  end

  it 'outputs a F for every failed test' do
    notifier.evaluate_finish(nil, [make_failure])

    assert !notifier.run_finish
    assert out.string == "F\n"
  end

  it 'outputs an E for every errored test' do
    notifier.evaluate_finish(nil, [make_error])

    assert !notifier.run_finish
    assert out.string == "E\n"
  end

  it_behaves_like_a ComposableNotifier
end

describe 'documentation notifier' do
  let(:notifier) { XSpec::Notifier::Documentation.new(out) }
  let(:out)      { StringIO.new }

  it 'outputs each context with a header and individual tests' do
    notifier.evaluate_finish(make_nested_test(['a'], 'b'), [])

    assert out.string == "\na\n  - b\n"
  end

  it 'adds an indent for each nested context' do
    notifier.evaluate_finish(make_nested_test(['a', 'b'], 'c'), [])

    assert out.string == "\na\n  b\n    - c\n"
  end

  it 'does not repeat top level parents for multiple nested contexts' do
    notifier.evaluate_finish(make_nested_test(['a', 'b'], 'c'), [])
    notifier.evaluate_finish(make_nested_test(['a', 'd'], 'e'), [])
    assert out.string == "\na\n  b\n    - c\n\n  d\n    - e\n"
  end

  it 'ignores contexts with no name' do
    notifier.evaluate_finish(make_nested_test([nil, 'a', nil], 'b'), [])

    assert out.string == "\na\n  - b\n"
  end

  it 'prefixes tests with F when they fail' do
    notifier.evaluate_finish(make_nested_test, [make_failure])

    assert out.string == "F \n"
  end

  it 'prefixes tests with E when they error' do
    notifier.evaluate_finish(make_nested_test, [make_error])

    assert out.string == "E \n"
  end

  it_behaves_like_a ComposableNotifier
end

describe 'composable notifier' do
  let(:notifier) { XSpec::Notifier::Composite.new }

  it_behaves_like_a ComposableNotifier
end

describe 'null notifier' do
  let(:notifier) { XSpec::Notifier::Null.new }

  it 'always returns true' do
    assert notifier.run_finish
  end

  it_behaves_like_a ComposableNotifier
end

def make_nested_test(parent_names = [], work_name = nil)
  XSpec::NestedUnitOfWork.new(
    parent_names.map {|name| XSpec::Context.make(name, Module.new) },
    XSpec::UnitOfWork.new(work_name, ->{})
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
