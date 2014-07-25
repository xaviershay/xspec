require 'spec_helper'

class LoadedClass
  def instance_method; end
  def self.class_method; end
end

describe 'doubles assertion context' do
  let(:subject) { Class.new { include XSpec::Evaluator.stack {
    include XSpec::Evaluator::Doubles
  }}.new }

  it 'converts double exceptions to failures' do
    result = subject.call(XSpec::UnitOfWork.new(nil, ->{
      raise XSpec::Evaluator::Doubles::DoubleFailure, "nope"
    }))
    assert_equal "nope", result[0].message
  end

  describe 'doubles of unloaded classes' do
    it 'allows any method to be expected' do
      assert_equal nil, subject.instance_eval {
        double = instance_double('Bogus')
        expect(double).foo
        double.foo
      }
    end

    it 'allows any return value to be specified' do
      assert_equal 1, subject.instance_eval {
        double = instance_double('Bogus')
        expect(double).foo("a") { 2 }
        expect(double).foo("b") { 3 }
        double.foo("b") - double.foo("a")
      }
    end

    it 'requires matching method name' do
      begin
        subject.instance_eval {
          double = instance_double('Bogus')
          expect(double).foo("a")
          double.bar("a")
        }
        fail "no error raised"
      rescue XSpec::Evaluator::Doubles::DoubleFailure => e
        assert_include "Unexpectedly received", e.message
        assert_include 'bar("a")', e.message
      end
    end

    it 'requires exact arguments' do
      begin
        subject.instance_eval {
          double = instance_double('Bogus')
          expect(double).foo("a")
          double.foo("b")
        }
        fail "no error raised"
      rescue XSpec::Evaluator::Doubles::DoubleFailure => e
        assert_include "Unexpectedly received", e.message
        assert_include 'foo("b")', e.message
      end
    end
  end

  describe 'assert_exhausted' do
    it 'passes if all expectations have been called' do
      assert subject.instance_eval {
        double = instance_double('Bogus')
        expect(double).foo
        double.foo
        assert_exhausted double
        true
      }
    end

    it 'raises when not all expectations have been called' do
      begin
        subject.instance_eval {
          double = instance_double('Bogus')
          expect(double).foo(1, "abc")
          assert_exhausted double
        }
        fail "no error raised"
      rescue XSpec::Evaluator::Doubles::DoubleFailure => e
        assert_include "did not receive", e.message
        assert_include 'foo(1, "abc")', e.message
      end
    end
  end

  describe 'instance_double' do
    describe 'when doubled class is loaded' do
      it 'allows instance methods to be expected' do
        assert subject.instance_eval {
          double = instance_double('LoadedClass')
          expect(double).instance_method { 123 }
        }
      end

      it 'does not allow non-existing methods to be expected' do
        begin
          assert subject.instance_eval {
            double = instance_double('LoadedClass')
            expect(double).bogus_method { 123 }
          }
          fail "no error raised"
        rescue XSpec::Evaluator::Doubles::DoubleFailure => e
          assert_include "LoadedClass#bogus_method", e.message
        end
      end
    end
  end

  describe 'class_double' do
    describe 'when doubled class is loaded' do
      it 'allows instance methods to be expected' do
        assert subject.instance_eval {
          double = class_double('LoadedClass')
          expect(double).class_method { 123 }
        }
      end

      it 'does not allow non-existing methods to be expected' do
        begin
          assert subject.instance_eval {
            double = class_double('LoadedClass')
            expect(double).bogus_method { 123 }
          }
          fail "no error raised"
        rescue XSpec::Evaluator::Doubles::DoubleFailure => e
          assert_include "LoadedClass.bogus_method", e.message
        end
      end
    end
  end
end

describe 'strict doubles assertion context' do
  let(:subject) { Class.new { include XSpec::Evaluator.stack {
    include XSpec::Evaluator::Doubles.with(:strict)
  }}.new }

  it 'allows doubling of loaded classes' do
    assert subject.instance_double("LoadedClass")
  end

  it 'prevents doubling of non-existing classes' do
    begin
      subject.instance_double("Bogus")
      fail "no error raised"
    rescue XSpec::Evaluator::Doubles::DoubleFailure => e
      assert_include "Bogus", e.message
    end
  end
end

describe 'auto-verifying doubles assertion context' do
  let(:subject) { Class.new { include XSpec::Evaluator.stack {
    include XSpec::Evaluator::Doubles.with(:auto_verify)
  }}.new }

  it 'verifies all used instance doubles on successful result' do
    result = subject.call(XSpec::UnitOfWork.new(nil, ->{
      double = instance_double('Bogus')
      expect(double).foo
    }))

    assert_equal 1, result.length
    assert_include "did not receive", result[0].message
    assert_include "foo()", result[0].message
  end

  it 'verifies all used class doubles on successful result' do
    result = subject.call(XSpec::UnitOfWork.new(nil, ->{
      double = class_double('Bogus')
      expect(double).foo
    }))

    assert_equal 1, result.length
    assert_include "did not receive", result[0].message
    assert_include "foo()", result[0].message
  end

  it 'does not verify doubles if errors occurred' do
    result = subject.call(XSpec::UnitOfWork.new(nil, ->{
      double = instance_double('Bogus')
      expect(double).foo
      fail "nope"
    }))
    assert_equal 1, result.length
    assert_include "nope", result[0].message
  end

  it 'returns successful result if all doubles are valid' do
    assert_equal [], subject.call(XSpec::UnitOfWork.new(nil, ->{}))
  end
end
