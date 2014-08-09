require 'spec_helper'

describe 'short ids' do
  def short_id_for(name)
    XSpec.default_short_id \
      XSpec::NestedUnitOfWork.new([], XSpec::UnitOfWork.new(name))
  end

  it 'is the same for same names' do
    assert_equal short_id_for("abc"), short_id_for("abc")
  end

  it 'is always the same length' do
    100.times do
      name = rand.to_s
      assert 3 == short_id_for(name).length, "#{name} had bad short id"
    end
  end
end
