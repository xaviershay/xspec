module XSpec
  module Notifier

    # Outputs a single character for each executed unit of work representing
    # the result.
    class Character
      def run_start; end

      def evaluate_finish(_, errors)
        if errors.any?
          @failed = true
          print 'F'
        else
          print '.'
        end
      end

      def run_finish
        puts
        !@failed
      end
    end

    # A notifier that does not do anything and always returns successful.
    # Useful as a parent class for other notifiers or for testing.
    class Null
      def run_start; end
      def evaluate_finish(*args); end
      def run_finish; true; end
    end

  end
end
