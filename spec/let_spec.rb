require 'spec_helper'

describe 'let' do
  let(:parent_value) { 1 }
  let(:object) { Object.new }

  describe 'allows locals to be set' do
    let(:my_value) { 2 }

    it { assert my_value == 2 }
  end

  describe 'inheriting from parent' do
    it { assert parent_value == 1 }
  end

  describe 'overriding parent' do
    let(:parent_value) { 2 }

    it { assert parent_value == 2 }
  end

  describe 'overriding parent with method' do
    def parent_value; 2; end

    it { assert parent_value == 2 }
  end

  describe 'can be defined after an it' do
    it { assert my_value == 2 }

    let(:my_value) { 2 }
  end

  it 'memoizes the value' do
    assert object == object
  end
end

let(:implicit_value) { 3 }

it 'let works with implicit context' do
  assert implicit_value == 3
end
