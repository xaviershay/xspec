# # Notifiers

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

      def evaluate_start(*args)
        notifiers.each {|x| x.evaluate_start(*args) }
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

      def evaluate_start(*_); end

      def evaluate_finish(result)
        @out.print label_for_failure(result.errors[0])
        @failed ||= result.errors.any?
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

    # Renders a histogram of test durations after the entire run is complete.
    class TimingsAtEnd
      include Composable

      DEFAULT_SPLITS = [0.001, 0.005, 0.01, 0.1, 1.0, Float::INFINITY]

      def initialize(out:    $stdout,
                     splits: DEFAULT_SPLITS,
                     width:  20)

        @timings = {}
        @splits  = splits
        @width   = width
        @out     = out
      end

      def run_start(*_); end

      def evaluate_start(_)
      end

      def evaluate_finish(result)
        timings[result] = result.duration
      end

      def run_finish
        buckets = bucket_from_splits(timings, splits)
        max     = buckets.values.max

        out.puts "           Timings:"
        buckets.each do |(split, count)|
          label = split.infinite? ? "∞" : split

          out.puts "    %6s %-#{width}s %i" % [
            label,
            '#' * (count / max.to_f * width.to_f).ceil,
            count
          ]
        end
        out.puts
      end

    private

      attr_reader :timings, :splits, :width, :out

      def bucket_from_splits(timings, splits)
        initial_buckets = splits.each_with_object({}) do |b, a|
          a[b] = 0
        end

        buckets = timings.each_with_object(initial_buckets) do |(_, d), a|
          split = splits.detect {|x| d < x }
          a[split] += 1
        end

        remove_trailing_zero_counts(buckets)
      end

      def remove_trailing_zero_counts(buckets)
        Hash[
          buckets
            .to_a
            .reverse
            .drop_while {|_, x| x == 0 }
            .reverse
        ]
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

      def evaluate_start(*_); end

      def evaluate_finish(result)
        self.errors += result.errors
      end

      def run_finish
        return true if errors.empty?

        out.puts
        errors.each do |error|
          out.puts "%s:\n%s\n\n" % [full_name(error.unit_of_work), error.message.lines.map {|x| "  #{x}"}.join("")]
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

    # Includes nicely formatted names and durations of each test in the output,
    # with color.
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

      def decorate(result)
        name = result.name
        out = if result.errors.any?
          colorize(append_failed(name), :red)
        else
          colorize(name , :green)
        end
        "%.3fs " % result.duration + out
      end

      def initialize(out = $stdout)
        self.indent          = 2
        self.last_seen_names = []
        self.failed          = false
        self.out             = out
      end

      def run_start; end

      def evaluate_start(*_); end

      def evaluate_finish(result)
        output_context_header! result.parents.map(&:name).compact

        spaces = ' ' * (last_seen_names.size * indent)

        self.failed ||= result.errors.any?

        out.puts "%s%s" % [spaces, decorate(result)]
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

    # Includes nicely formatted names and durations of each test in the output.
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
      def evaluate_start(*_); end
      def evaluate_finish(*_); end
      def run_finish; true; end
    end

    DEFAULT =
      ColoredDocumentation.new +
      TimingsAtEnd.new +
      FailuresAtEnd.new
  end
end
