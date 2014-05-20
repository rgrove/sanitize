# Biased comparison of Ruby HTML sanitization libraries

This is a feature comparison of several widely used Ruby HTML sanitization
libraries. It's heavily biased because I'm the author of Sanitize, and I've
chosen to list the features that are important to me.

If these features are also important to you, then you may find this comparison
useful. If other features are important to you, or if you'd prefer to get this
information from someone who isn't the author of one of the libraries in the
comparison, then I recommend you do your own research.

Spot a mistake or some outdated info? Please [file an issue][issues] and let me
know!

[issues]:https://github.com/rgrove/sanitize/issues

## Feature comparison

Feature                                               | [Sanitize 3.0.0][sanitize] | [Loofah 2.0.0][loofah] | [HTMLFilter 1.3.0][htmlfilter] |
----------------------------------------------------- |:--------------------------:|:----------------------:|:------------------------------:|
Actually parses HTML (not with regexes)               | ✓                          | ✓                      |                                |
HTML5-compliant parser                                | ✓                          |                        |                                |
Fixes up badly broken/malicious markup                | ✓                          | ✓                      |                                |
Fully configurable whitelists                         | ✓                          | hard-coded only        | ✓                              |
Global attribute whitelist                            | ✓                          | ✓                      |                                |
Element-specific attribute whitelist                  | ✓                          |                        | ✓                              |
Attribute-specific protocol whitelist                 | ✓                          |                        | ✓                              |
Supports HTML5 `data-` attributes                     | ✓                          | ✓                      |                                |
Optionally escapes unsafe HTML instead of removing it |                            | ✓                      |                                |
Allows custom manual HTML manipulation (transformers) | ✓                          | ✓                      |                                |
Built-in MathML support                               |                            | always enabled         |                                |
Built-in SVG support                                  |                            | always enabled         |                                |
Basic CSS sanitization                                |                            | regex-based            | regex-based                    |

### Notes

* Sanitize and Loofah both use [Nokogiri][nokogiri] to manipulate parsed HTML,
  but Loofah uses Nokogiri's non-HTML5-compliant libxml2 parser. Sanitize uses
  the HTML5-compliant [Google Gumbo parser][gumbo], which uses the exact same
  parsing algorithm as modern browsers. HTMLFilter performs all its manipulation
  using regexes and does not actually parse HTML.

* Both Sanitize and Loofah fix up badly broken, misnested, or maliciously
  crafted HTML and output valid syntactically valid markup. Sanitize's HTML5
  parser handles a wider variety of edge cases than Loofah's libxml2 parser.
  HTMLFilter does basic tag balancing but not much more, and garbage in
  generally results in garbage out.

* Loofah's whitelist configuration is hard-coded and can only be customized by
  either editing its source or monkeypatching. Sanitize and HTMLFilter both have
  easily customizable whitelist configurations.

* Loofah has a single global whitelist for attributes, which it uses for all
  elements. HTMLFilter has per-element attribute whitelists, but provides no way
  to whitelist global attributes (i.e., attributes that should be allowed on any
  element). Sanitize supports both globally and element-specific attribute
  whitelists.

* Sanitize and Loofah both support HTML5 data attributes. In Sanitize, data
  attributes can be enabled or disabled in either the global or element-specific
  whitelists. Loofah always allows data attributes on all elements, and this is
  not configurable. HTMLFilter does not support data attributes.

* Both Sanitize and Loofah allow you to write blocks or methods that can perform
  custom manipulation on HTML nodes as they're traversed. Sanitize calls them
  "transformers", whereas Loofah calls them "scrubbers". They're more or less
  equivalent in terms of the functionality they allow.

* Loofah has hard-coded whitelists for sanitizing MathML and SVG, which cannot
  be disabled via configuration. Sanitize does not provide built-in configs for
  sanitizing MathML or SVG, but it would be fairly trivial to add MathML and
  SVG elements and attributes to a custom whitelist config.

* Loofah and HTMLFilter both perform very rudimentary regex-based CSS
  sanitization, but I wouldn't trust either of them to actually sanitize
  maliciously crafted CSS. Sanitize does not currently offer any form of
  built-in CSS sanitization.

[gumbo]:https://github.com/google/gumbo-parser
[nokogiri]:http://nokogiri.org/

## Performance comparison

Based on [this synthetic benchmark][benchmark]. Smaller numbers are better (they
indicate faster completion).

[benchmark]:https://github.com/rgrove/sanitize/tree/dev-3.0.0/benchmark

Benchmark                                | [Sanitize 3.0.0][sanitize]             | [Loofah 2.0.0][loofah]               | [HTMLFilter 1.3.0][htmlfilter]
---------------------------------------- |:--------------------------------------:|:------------------------------------:|:------------------------------:
Small HTML fragment (757 bytes) x 1000   | <br>0.848s strip / 0.833s prune        | **✓<br>0.713s strip / 0.715s prune** | 1.215s
Large HTML fragment (33531 bytes) x 100  | **✓<br>3.421s strip / 3.427s prune**   | <br>5.358s strip / 5.367s prune      | 10.455s
Small HTML document (25286 bytes) x 100  | **✓<br>1.651s strip / 1.621s prune**   | <br>2.449s strip / 2.411s prune      | _ERROR_
Medium HTML document (86685 bytes) x 100 | **✓<br>6.217s strip / 6.137s prune**   | <br>10.885s strip / 10.539s prune    | _ERROR_
Huge HTML document (7172510 bytes) x 5   | **✓<br>31.653s strip / 31.916s prune** | <br>53.152s strip / 56.393s prune    | 108.433s

To run this benchmark yourself:

```
git clone https://github.com/rgrove/sanitize.git
cd sanitize
git checkout dev-3.0.0
bundle install
gem install loofah hitimes htmlfilter
ruby benchmark/benchmark.rb
```

### Notes

* During the small and medium document benchmarks, HTMLFilter raised an
  `Encoding::CompatibilityError` exception. Both documents are UTF-8 encoded,
  but HTMLFilter's source files don't declare their own encoding, which is a
  bug.

### Raw benchmark results

```
Ruby version      : 2.1.0
Sanitize version  : 3.0.0
Loofah version    : 2.0.0
HTMLFilter version: 1.3.0

Nokogiri version: {"warnings"=>[], "nokogiri"=>"1.6.2.1", "ruby"=>{"version"=>"2.1.0", "platform"=>"x86_64-darwin13.0", "description"=>"ruby 2.1.0p0 (2013-12-25 revision 44422) [x86_64-darwin13.0]", "engine"=>"ruby"}, "libxml"=>{"binding"=>"extension", "source"=>"packaged", "libxml2_path"=>"/Users/rgrove/.rbenv/versions/2.1.0/lib/ruby/gems/2.1.0/gems/nokogiri-1.6.2.1/ports/x86_64-apple-darwin13.0.0/libxml2/2.8.0", "libxslt_path"=>"/Users/rgrove/.rbenv/versions/2.1.0/lib/ruby/gems/2.1.0/gems/nokogiri-1.6.2.1/ports/x86_64-apple-darwin13.0.0/libxslt/1.1.28", "compiled"=>"2.8.0", "loaded"=>"2.8.0"}}

These values are time measurements. Lower is faster!

-- Benchmark --
  Small HTML fragment (757 bytes) x 1000
                                   total    single    rel
       Sanitize.fragment (strip)   0.848 (0.000848)     -
       Sanitize.fragment (prune)   0.833 (0.000833)  0.98x
                   Loofah :strip   0.713 (0.000713)  0.84x
                   Loofah :prune   0.715 (0.000715)  0.84x
                      HTMLFilter   1.215 (0.001215)  1.43x

  Large HTML fragment (33531 bytes) x 100
                                   total    single    rel
       Sanitize.fragment (strip)   3.421 (0.034205)     -
       Sanitize.fragment (prune)   3.427 (0.034273)  1.00x
                   Loofah :strip   5.358 (0.053582)  1.57x
                   Loofah :prune   5.367 (0.053675)  1.57x
                      HTMLFilter  10.455 (0.104553)  3.06x

  Small HTML document (25286 bytes) x 100
                                   total    single    rel
       Sanitize.document (strip)   1.651 (0.016506)     -
       Sanitize.document (prune)   1.621 (0.016207)  0.98x
                   Loofah :strip   2.449 (0.024488)  1.48x
                   Loofah :prune   2.411 (0.024114)  1.46x
               HTMLFilter ERROR!

  Medium HTML document (86685 bytes) x 100
                                   total    single    rel
       Sanitize.document (strip)   6.217 (0.062172)     -
       Sanitize.document (prune)   6.137 (0.061366)  0.99x
                   Loofah :strip  10.885 (0.108846)  1.75x
                   Loofah :prune  10.539 (0.105387)  1.70x
               HTMLFilter ERROR!

  Huge HTML document (7172510 bytes) x 5
                                   total    single    rel
       Sanitize.document (strip)  31.653 (6.330614)     -
       Sanitize.document (prune)  31.916 (6.383101)  1.01x
                   Loofah :strip  53.152 (10.630404)  1.68x
                   Loofah :prune  56.393 (11.278685)  1.78x
                      HTMLFilter 108.433 (21.686670)  3.43x
```


[htmlfilter]:https://github.com/rubyworks/htmlfilter
[loofah]:https://github.com/flavorjones/loofah
[sanitize]:https://github.com/rgrove/sanitize
