require 'spec_helper'

require 'xspec/assertion_contexts'

it 'integrates with rspec' do
  opts = {
    assertion_context: XSpec::AssertionContext::RSpecExpectations.new
  }

  context = with_dsl(opts) do
    it 'supports expect an eq' do
      expect(1 + 1).to eq(3)
    end
  end

  assert_errors_from_run context, [
    "\nexpected: 3\n     got: 2\n\n(compared using ==)\n"
  ]
end
