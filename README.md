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
> xspec example.rb

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

### Customization

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

Of course, you can make your own extension classes as well. For details, see
the "Configuration" section of the documentation.

Documentation
-------------

There are two major sources of documentation:

* [Main API documentation.](https://xaviershay.github.io/xspec/api.html)
* [Literate source code.](https://xaviershay.github.io/xspec/)

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
    bundle exec bin/run-specs
