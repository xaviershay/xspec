require 'spec_helper'
require 'stringio'

describe 'failures at end notifier' do
  let(:notifier) { XSpec::Notifier::FailuresAtEnd.new(out) }
  let(:out)      { StringIO.new }

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

  def make_nested_test(parent_names, work_name)
    XSpec::NestedUnitOfWork.new(
      parent_names.map {|name| XSpec::Context.new(name, nil) },
      XSpec::UnitOfWork.new(work_name, ->{})
    )
  end
end
