# Without a notifier, there is no way for XSpec to interact with the outside
# world. A notifier handles progress updates as tests are executed, and
# summarizing the run when it finished.
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
      include Composable

      def initialize(*notifiers)
        @notifiers = notifiers
      end

      def run_start
        notifiers.each(&:run_start)
      end

      def evaluate_finish(*args)
        notifiers.each {|x| x.evaluate_finish(*args) }
      end

      def run_finish
        notifiers.map(&:run_finish).all?
      end

      protected

      attr_reader :notifiers
    end

    # Outputs a single character for each executed unit of work representing
    # the result.
    class Character
      include Composable

      def initialize(out = $stdout)
        @out = out
      end

      def run_start; end

      def evaluate_finish(_, errors)
        @out.print label_for_failure(errors[0])
        @failed ||= errors.any?
      end

      def run_finish
        @out.puts
        !@failed
      end

      protected

      def label_for_failure(f)
        case f
          when CodeException then 'E'
          when Failure then 'F'
          else '.'
        end
      end

    end

    # Outputs error messages and backtraces after the entire run is complete.
    class FailuresAtEnd
      include Composable

      def initialize(out = $stdout)
        @errors = []
        @out    = out
      end

      def run_start; end

      def evaluate_finish(_, errors)
        self.errors += errors
      end

      def run_finish
        return true if errors.empty?

        out.puts
        errors.each do |error|
          out.puts "%s: %s" % [full_name(error.unit_of_work), error.message]
          clean_backtrace(error.caller).each do |line|
            out.puts "  %s" % line
          end
          out.puts
        end

        false
      end

      def full_name(unit_of_work)
        (unit_of_work.parents + [unit_of_work]).map(&:name).compact.join(' ')
      end

      # A standard backtrace contains many entries for XSpec itself which are
      # not useful for debugging your tests, so they are stripped out.
      def clean_backtrace(backtrace)
        lib_dir = File.dirname(File.expand_path('..', __FILE__))

        backtrace.reject {|x|
          File.dirname(x).start_with?(lib_dir)
        }
      end

      protected

      attr_accessor :out, :errors
    end

    # Includes nicely formatted names of each test in the output, with color.
    class ColoredDocumentation
      require 'set'

      include Composable

      VT100_COLORS = {
        :black   => 30,
        :red     => 31,
        :green   => 32,
        :yellow  => 33,
        :blue    => 34,
        :magenta => 35,
        :cyan    => 36,
        :white   => 37
      }

      def color_code_for(color)
        VT100_COLORS.fetch(color)
      end

      def colorize(text, color)
        "\e[#{color_code_for(color)}m#{text}\e[0m"
      end

      def decorate(name, errors)
        color = if errors[0]
          colorize(append_failed(name), :red)
        else
          colorize(name, :green)
        end
      end

      def initialize(out = $stdout)
        self.indent          = 2
        self.last_seen_names = []
        self.failed          = false
        self.out             = out
      end

      def run_start; end

      def evaluate_finish(unit_of_work, errors)
        output_context_header! unit_of_work.parents.map(&:name).compact

        spaces = ' ' * (last_seen_names.size * indent)

        self.failed ||= errors.any?

        out.puts "%s%s" % [spaces, decorate(unit_of_work.name, errors)]
      end

      def run_finish
        out.puts
        !failed
      end

      protected

      attr_accessor :last_seen_names, :indent, :failed, :out

      def output_context_header!(parent_names)
        if parent_names != last_seen_names
          tail = parent_names - last_seen_names

          out.puts
          if tail.any?
            existing_indent = parent_names.size - tail.size
            tail.each_with_index do |name, i|
              out.puts '%s%s' % [' ' * ((existing_indent + i) * indent), name]
            end
          end

          self.last_seen_names = parent_names
        end
      end

      def append_failed(name)
        [name, "FAILED"].compact.join(' - ')
      end
    end

    # Includes nicely formatted names of each test in the output.
    class Documentation < ColoredDocumentation
      def colorize(name, _)
        name
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
