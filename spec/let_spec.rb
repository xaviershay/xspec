require 'spec_helper'

let(:root_value) { 3 }

describe 'let' do
  let(:parent_value) { 1 }
  let(:object) { Object.new }

  it('allows locals to be set') { assert parent_value == 1 }

  describe do
    it("inherits from parent") { assert parent_value == 1 }
  end

  describe do
    let(:parent_value) { 2 }

    it('allows overriding of parent') { assert parent_value == 2 }
  end

  describe do
    def parent_value; 2; end

    it('allows overriding of parent by method') { assert parent_value == 2 }
  end

  describe do
    it('can be defined after an it') { assert my_value == 2 }

    let(:my_value) { 2 }
  end

  it 'memoizes the value' do
    assert object == object
  end

  it 'works with root context' do
    assert root_value == 3
  end
end

