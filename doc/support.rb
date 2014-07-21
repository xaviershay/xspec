require 'xspec'

$initial = Object.constants

module ExpectToFail
  def expect_to_fail!
    @expect_to_fail = true
  end

  def call(uow)
    result = super
    return result unless @expect_to_fail

    if result.empty?
      [XSpec::Failure.new(uow, "expected failure", [])]
    else
      []
    end
  end
end

def documentation_stack(&block)
  Module.new do
    include XSpec::AssertionContext::Bottom
    instance_exec &block if block
    include XSpec::AssertionContext::Top
    include ExpectToFail
  end
end

