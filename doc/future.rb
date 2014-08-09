# # Future ideas
#
# This page sketches ideas for future features that may or may not be
# implemented.
#
# ## Shared Contexts
# Common specs can be shared among different contexts. This feature acts
# similar to normal Ruby module inclusion. Use `shared_context` to create a
# shared set of specs, and `include_context` to apply them elsewhere.
require_relative './support'

module SharedContexts
  extend XSpec.dsl

  EvenNumber = shared_context do
    it 'is divisible by two' do
      assert_equal 0, number % 2
    end
  end

  describe 'two' do
    let(:number) { 2 }
    include_context EvenNumber
  end

  describe 'four' do
    let(:number) { 4 }
    include_context EvenNumber
  end
end

def self.run!(*args)
  exit 1 unless [
    SharedContexts,
  ].map {|x|
    x.run!(*args)
  }.all?
end
