require 'spec_helper'

describe 'simple assertion context' do
  let(:subject) { Class.new { include XSpec::AssertionContext::Simple }.new }

  describe 'assert_equal' do
    it 'succeeds if parameters are equal' do
      subject.assert_equal("a", "a")
    end

    it 'fails if parameters are not equal' do
      begin
        subject.assert_equal("a", "b")
        fail "Assertion did not fail"
      rescue XSpec::AssertionContext::Simple::AssertionFailed => e
        assert [
          e.message =~ /expected: "a"/,
          e.message =~ /got: "b"/
        ].all?, "Message did not match expected: #{e.message.inspect}"
      end
    end
  end

  describe 'fail' do
    it 'always fails' do
      begin
        subject.fail
        assert false, "fail did not fail"
      rescue XSpec::AssertionContext::Simple::AssertionFailed => e
        assert_equal "failed", e.message
      end
    end

    it 'can fail with a custom message' do
      begin
        subject.fail ":("
        assert false, "fail did not fail"
      rescue XSpec::AssertionContext::Simple::AssertionFailed => e
        assert_equal ":(", e.message
      end
    end
  end
end
