require 'spec_helper'

describe 'simple assertion context' do
  let(:subject) { Class.new { include XSpec::Evaluator.stack {
    include XSpec::Evaluator::Simple
  }}.new }

  describe 'assert' do
    it 'succeeds if parameter is true' do
      subject.assert(true)
    end

    it 'fails with default message if parameter is false' do
      begin
        subject.assert(false)
        fail "Assertion did not fail"
      rescue XSpec::Evaluator::EvaluateFailed => e
        assert_equal "assertion failed", e.message
      end
    end

    it 'fails with custom message if parameter is false' do
      begin
        subject.assert(false, "nope")
        fail "Assertion did not fail"
      rescue XSpec::Evaluator::EvaluateFailed => e
        assert_equal "nope", e.message
      end
    end
  end

  describe 'assert_equal' do
    it 'succeeds if parameters are equal' do
      subject.assert_equal("a", "a")
    end

    it 'fails if parameters are not equal' do
      begin
        subject.assert_equal("a", "b")
        fail "Assertion did not fail"
      rescue XSpec::Evaluator::EvaluateFailed => e
        assert_include 'want: "a"', e.message
        assert_include 'got: "b"', e.message
      end
    end
  end

  describe 'fail' do
    it 'always fails' do
      begin
        subject.fail
        assert false, "fail did not fail"
      rescue XSpec::Evaluator::EvaluateFailed => e
        assert_equal "failed", e.message
      end
    end

    it 'can fail with a custom message' do
      begin
        subject.fail ":("
        assert false, "fail did not fail"
      rescue XSpec::Evaluator::EvaluateFailed => e
        assert_equal ":(", e.message
      end
    end
  end
end
