XSpec
=====

XSpec is an rspec-inspired testing library that is written in a literate style
and designed to be obvious to use, highly modular, and easy to extend.

Open up `lib/xspec.rb` and start reading, or use this [nicely formatted
version](http://xaviershay.github.io/xspec/).

Usage
-----

The default configuration XSpec provides a number of interesting features:
assertions, doubles, and rich output.

``` ruby
require 'xspec'

extend XSpec.dsl # Use defaults

describe 'my application' do
  it 'does math' do
    double = instance_double('Calculator')
    expect(double).add(1, 1) { 2 }

    assert_equal 2, double.add(1, 1)
  end

  it 'is slow sometimes' do
    sleep 0.01
  end

  it 'fails' do
    assert_include "fruit", "punch"
  end
end
```

Running this with the built-in runner generates some pretty output. You can't
see the colors in this README, but trust me they are quite lovely.

```
> bin/xspec example.rb

my application
  0.000s does math
  0.011s is slow sometimes
  0.000s fails - FAILED

           Timings:
     0.001 #################### 2
     0.005                      0
      0.01                      0
       0.1 ##########           1


my application fails:
  "fruit" not present in: "punch"

  example.rb:18:in `block (2 levels) in <top (required)>'
  bin/xspec:19:in `<main>'
```

Customization
-------------

Every aspect of XSpec is customizable, from how tests are scheduled and run all
the way through to formatting of output.

Say you wanted boring output with no support for doubles and RSpec
expectations. You could do that:

``` ruby
require 'xspec'

extend XSpec.dsl(
  assertion_context: XSpec::AssertionContext.stack {
    include XSpec::AssertionContext::RSpecExpectations
  },
  notifier: XSpec::Notifiers::Character.new +
            XSpec::Notifiers::FailuresAtEnd.new
)

describe '...' do
  # etc etc
end
```

Of course, you can easily make your own extension classes as well. A runner
that randomly drops tests and reports random durations? Whatever floats your
boat:

``` ruby
require 'xspec'

class UnhelpfulRunner
  attr_reader :notifier

  def initialize(opts)
    @notifier = opts.fetch(:notifier)
  end

  def run(context)
    notifier.run_start

    context.nested_units_of_work.each do |x|
      next if rand > 0.9

      notifier.evaluate_start(x)

      errors   = x.immediate_parent.execute(x)
      duration = rand
      result   = XSpec::ExecutedUnitOfWork.new(x, errors, duration)

      notifier.evaluate_finish(result)
    end

    notifier.run_finish
  end
end

extend XSpec.dsl(
  evaluator: UnhelpfulRunner.new(notifier: XSpec::Notifier::DEFAULT)
)

describe '...' do
  # etc etc
end
```

Developing
----------

Follow the idioms you find in the source, they are somewhat different than
a traditional Ruby project. Bug fixes welcome, features likely to be rejected
since I have a strong opinion of what this library should and should not do.
Talk to me before embarking on anything large. Tests are written in XSpec,
which might do your head in:

    bundle install
    bundle exec bin/run-specs
