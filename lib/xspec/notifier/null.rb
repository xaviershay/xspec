# A notifier that does not do anything and always returns successful. Useful as
# a parent class for other notifiers or for testing.
module XSpec
  module Notifier
    class Null
      def run_start; end
      def evaluate_finish(*args); end
      def run_finish; true; end
    end
  end
end
