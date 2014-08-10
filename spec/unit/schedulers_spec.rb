require 'spec_helper'

describe 'schedulers' do
  let(:recording_notifier) { Class.new do
      include XSpec::Notifier::Empty

      attr_reader :results

      def evaluate_finish(result)
        @results ||= []
        @results << result
      end
    end.new
  }

  describe 'threaded' do
    it 'runs all tests' do
      context = with_dsl(
        notifier:  recording_notifier,
        scheduler: XSpec::Scheduler::Threaded.new
      ) do
        it('a') {}
        it('b') {}
        it('c') {}
      end

      assert_equal true, context.run!

      assert_equal %w(a b c), recording_notifier.results.map(&:full_name).sort
    end
  end

  describe 'filter' do
    it 'runs tests matching proc' do
      context = with_dsl(
        notifier:  recording_notifier,
        scheduler: XSpec::Scheduler::Filter.new(
          scheduler: XSpec::Scheduler::DEFAULT,
          filter:    -> uow { uow.full_name.to_i.odd? }
        )
      ) do
        it('1') {}
        it('2') {}
        it('3') {}
      end

      assert_equal true, context.run!

      assert_equal %w(1 3), recording_notifier.results.map(&:full_name).sort
    end
  end
end
