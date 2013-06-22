# Outputs a single character for each unit of work representing the result.
module XSpec
  module Notifier

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
  end
end
