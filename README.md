XSpec
=====

XSpec is an rspec-inspired testing library for Ruby that is written in a
literate style and designed to be obvious to use, highly modular, and easy to
extend.

Usage
-----

    gem install xspec

The default configuration XSpec provides a number of interesting features:
assertions, doubles, and rich output.

``` ruby
require 'xspec'

extend XSpec.dsl # Use defaults

describe 'my application' do
  it 'does math' do
    double = instance_double('Calculator')
    stub(double).add(1, 1) { 2 }

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
> xspec example.rb

my application
  0.000s 3l1 does math
  0.011s f0j is slow sometimes
  0.000s juj fails - FAILED

           Timings:
     0.001 #################### 2
     0.005                      0
      0.01                      0
       0.1 ##########           1


juj - my application fails
  "fruit" not present in: "punch"

  test.rb:17:in `block (2 levels) in <top (required)>'
  bin/xspec:44:in `<main>'
```

The three-character tag next to each test is its short id. You can use it to
run a single test:

```
> xspec -f 3l1

my application
  0.000s 3l1 does math

           Timings:
     0.001 #################### 1

```

### Customization

Every aspect of XSpec is customizable, from how tests are scheduled and run all
the way through to formatting of output.

Say you wanted boring output with no support for doubles and RSpec
expectations. You could do that:

``` ruby
require 'xspec'

extend XSpec.dsl(
  evaluator_context: XSpec::Evaluator.stack {
    include XSpec::Evaluator::RSpecExpectations
  },
  notifier: XSpec::Notifier::Character.new +
            XSpec::Notifier::FailuresAtEnd.new
)

describe '...' do
  # etc etc
end
```

Of course, you can make your own extension classes as well. For details, see
the API documentation.

Documentation
-------------

There are two major sources of documentation:

* [Main API documentation.](https://xaviershay.github.io/xspec/docs/api.html)
* [Literate source code.](https://xaviershay.github.io/xspec/docs/xspec.html)

It is expected that regular users of XSpec will read both at least once. There
isn't much to them, and they will give you a useful mental model of how XSpec
works.

Developing
----------

Follow the idioms you find in the source, they are somewhat different than
a traditional Ruby project. Bug fixes welcome, though features are likely to be
rejected since I have a strong opinion of what this library should and should
not do. Talk to me before embarking on anything large. Tests are written in
XSpec, which might do your head in:

    bundle install
    bundle exec bin/xspec
