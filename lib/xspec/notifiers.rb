module XSpec
  module Notifier
    # Many notifiers play nice with others, and can be composed together in a
    # way that each notifier will have its callback run in turn.
    module Composable
      def +(other)
        Composite.new(self, other)
      end
    end

    class Composite
      def initialize(*notifiers)
        @notifiers = notifiers
      end

      def run_start;  notifiers.each(&:run_start); end
      def run_finish; notifiers.each(&:run_finish); end

      def evaluate_finish(*args)
        notifiers.map {|x| x.evaluate_finish(*args) }.all?
      end

      protected

      attr_reader :notifiers
    end

    # Outputs a single character for each executed unit of work representing
    # the result.
    class Character
      include Composable

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

    # Outputs error messages and backtraces after the entire run is complete.
    class FailuresAtEnd
      include Composable

      def initialize
        @errors = []
      end

      def run_start; end

      def evaluate_finish(_, errors)
        @errors += errors
      end

      def run_finish
        return true if @errors.empty?

        puts
        @errors.each do |error|
          puts "%s: %s" % [error.unit_of_work.name, error.message]
          error.caller.each do |line|
            puts "  %s" % line
          end
          puts
        end

        false
      end
    end

    # Includes nicely formatted names of each test in the output.
    class Documentation
      include Composable

      def initialize(indent = 2)
        self.indent          = indent
        self.last_seen_names = []
        self.failed          = false
      end

      def run_start; end

      def evaluate_finish(unit_of_work, errors)
        output_context_header! unit_of_work.parents.map(&:name).compact

        spaces = ' ' * (last_seen_names.size * indent)
        char   = '-'

        if errors.any?
          self.failed = true
          char        = 'F'
        end

        puts "%s%s %s" % [spaces, char, unit_of_work.name]
      end

      def run_finish
        puts
        !failed
      end

      protected

      attr_accessor :last_seen_names, :indent, :failed

      def output_context_header!(parent_names)
        if parent_names != last_seen_names
          tail = parent_names - last_seen_names

          puts
          if tail.any?
            existing_indent = parent_names.size - tail.size
            tail.each_with_index do |name, i|
              puts '%s%s' % [' ' * ((existing_indent + i) * indent), name]
            end
          end

          self.last_seen_names = parent_names
        end
      end
    end

    # A notifier that does not do anything and always returns successful.
    # Useful as a parent class for other notifiers or for testing.
    class Null
      include Composable

      def run_start; end
      def evaluate_finish(*args); end
      def run_finish; true; end
    end

  end
end
