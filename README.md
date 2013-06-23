XSpec
=====

XSpec is an rspec-inspired testing library that is written in a literate style
and designed to be highly modular and easy to extend.

You probably do not want to actually use it, it is more interesting as
a pedagogical piece.

Open up `lib/xspec.rb` and start reading, or use this [nicely formatted
version](http://xaviershay.github.io/xspec/).

Usage
-----

The basics are unexciting:

``` ruby
require 'xspec/autorun'

describe 'my application' do
  it 'does math' do
    assert 1 + 1 == 2
  end
end
```

It is when you start customizing that things become interesting:

``` ruby
require 'xspec'

extend XSpec.dsl(
  notifier: KlaxonOnRedNotifer.new
)
autorun!

describe '...' do
  # etc etc
end
```

Developing
----------

Follow the idioms you find in the source, they are somewhat different than
a traditional Ruby project. Tests are written in XSpec, which might do your
head in.

    bin/run-specs
