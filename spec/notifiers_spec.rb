require 'spec_helper'
require 'stringio'

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

  def make_nested_test(parent_names, work_name)
    XSpec::NestedUnitOfWork.new(
      parent_names.map {|name| XSpec::Context.make(name, Module.new) },
      XSpec::UnitOfWork.new(work_name, ->{})
    )
  end
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
    notifier.evaluate_finish(nil, ["failure"])

    assert !notifier.run_finish
    assert out.string == "F\n"
  end
end
