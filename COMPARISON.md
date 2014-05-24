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
Fully configurable whitelists                         | ✓                          |                        | ✓                              |
Global attribute whitelist                            | ✓                          | ✓ (hard-coded)         |                                |
Element-specific attribute whitelist                  | ✓                          |                        | ✓                              |
Attribute-specific protocol whitelist                 | ✓                          |                        | ✓                              |
Supports HTML5 `data-` attributes                     | ✓                          | ✓ (hard-coded)         |                                |
Optionally escapes unsafe HTML instead of removing it |                            | ✓                      |                                |
Allows custom HTML manipulation (transformers)        | ✓                          | ✓                      |                                |
Built-in MathML support                               |                            | always enabled         |                                |
Built-in SVG support                                  |                            | always enabled         |                                |
Basic CSS sanitization                                | ✓                          | regex-based            | regex-based                    |
Advanced whitelist-based CSS sanitization             | ✓                          |                        |                                |

### Notes

* Sanitize and Loofah both use [Nokogiri][nokogiri] to manipulate parsed HTML,
  but Loofah uses Nokogiri's non-HTML5-compliant libxml2 parser. Sanitize uses
  the HTML5-compliant [Google Gumbo parser][gumbo], which uses the exact same
  parsing algorithm as modern browsers. HTMLFilter performs all its manipulation
  using regexes and does not actually parse HTML.

* Both Sanitize and Loofah fix up badly broken, misnested, or maliciously
  crafted HTML and output syntactically valid markup. Sanitize's HTML5 parser
  handles a wider variety of edge cases than Loofah's libxml2 parser. HTMLFilter
  does basic tag balancing but not much more, and garbage in generally results
  in garbage out.

* Loofah's whitelist configuration is hard-coded and can only be customized by
  either editing its source or monkeypatching. Sanitize and HTMLFilter both have
  easily customizable whitelist configurations.

* Loofah has a single global whitelist for attributes, which it uses for all
  elements. HTMLFilter has per-element attribute whitelists, but provides no way
  to whitelist global attributes (i.e., attributes that should be allowed on any
  element, such as `class`). Sanitize supports both global and element-specific
  attribute whitelists.

* Sanitize and Loofah both support HTML5 data attributes. In Sanitize, data
  attributes can be enabled or disabled in either the global or element-specific
  whitelists. Loofah always allows data attributes on all elements, and this is
  not configurable. HTMLFilter does not support data attributes.

* Both Sanitize and Loofah allow you to write blocks or methods that can perform
  custom manipulation on HTML nodes as they're traversed. Sanitize calls them
  "transformers", whereas Loofah calls them "scrubbers". They're more or less
  equivalent in terms of functionality.

* Loofah has hard-coded whitelists for sanitizing MathML and SVG, which cannot
  be disabled via configuration. Sanitize does not provide built-in configs for
  sanitizing MathML or SVG, but it would be fairly trivial to add MathML and
  SVG elements and attributes to a custom whitelist config.

* Sanitize performs advanced whitelist-based CSS sanitization using
  [Crass][crass], a full-fledged CSS parser compliant with the CSS Syntax Module
  Level 3 parsing spec. Loofah and HTMLFilter both perform rudimentary
  regex-based CSS sanitization, but I wouldn't trust either of them to actually
  sanitize maliciously crafted CSS.

[crass]:https://github.com/rgrove/crass
[gumbo]:https://github.com/google/gumbo-parser
[nokogiri]:http://nokogiri.org/

## Performance comparison

**Note:** Sanitize 3.0.0 is currently under active development, so its numbers
may change as the code changes. I'll re-run these benchmarks once 3.0.0 is ready
for release to get final numbers.

Based on [this synthetic benchmark][benchmark]. Smaller numbers are better (they
indicate faster completion).

[benchmark]:https://github.com/rgrove/sanitize/tree/dev-3.0.0/benchmark

Benchmark                                  | [Sanitize 3.0.0][sanitize]             | [Loofah 2.0.0][loofah]               | [HTMLFilter 1.3.0][htmlfilter]
------------------------------------------ |:--------------------------------------:|:------------------------------------:|:------------------------------:
Small HTML fragment (757 bytes) x 1000     | <br>1.077s strip / 1.077s prune        | **✓<br>0.524s strip / 0.522s prune** | 0.876s
Large HTML fragment (33,531 bytes) x 100   | **✓<br>3.281s strip / 3.316s prune**   | <br>3.950s strip / 4.050s prune      | 7.437s
Small HTML document (25,286 bytes) x 100   | **✓<br>1.648s strip / 1.639s prune**   | <br>1.855s strip / 1.841s prune      | _ERROR_
Medium HTML document (86,685 bytes) x 100  | **✓<br>5.911s strip / 5.876s prune**   | <br>7.598s strip / 7.479s prune      | _ERROR_
Huge HTML document (7,172,510 bytes) x 5   | **✓<br>30.324s strip / 32.929s prune** | <br>44.056s strip / 40.845s prune    | 73.933s

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

* Sanitize's performance can be improved significantly on multiple runs by
  reusing a single configured instance. However, since neither Loofah nor
  HTMLFilter support a similar usage style, I chose not to take advantage of
  this in these benchmarks for the sake of fairness. This is why Sanitize loses
  the small fragment benchmark: its instantiation overhead outweighs its faster
  parsing and sanitization speed.

* During the small and medium document benchmarks, HTMLFilter raised an
  `Encoding::CompatibilityError` exception. Both documents are UTF-8 encoded,
  but HTMLFilter's source files don't declare their own encoding, which is a
  bug.

### Raw benchmark results

```
Ruby version      : 2.1.2
Sanitize version  : 3.0.0
Loofah version    : 2.0.0
HTMLFilter version: 1.3.0

Nokogiri version: {"warnings"=>[], "nokogiri"=>"1.6.2.1", "ruby"=>{"version"=>"2.1.2", "platform"=>"x86_64-darwin13.0", "description"=>"ruby 2.1.2p95 (2014-05-08 revision 45877) [x86_64-darwin13.0]", "engine"=>"ruby"}, "libxml"=>{"binding"=>"extension", "source"=>"packaged", "libxml2_path"=>"/Users/rgrove/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/gems/nokogiri-1.6.2.1/ports/x86_64-apple-darwin13.2.0/libxml2/2.8.0", "libxslt_path"=>"/Users/rgrove/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/gems/nokogiri-1.6.2.1/ports/x86_64-apple-darwin13.2.0/libxslt/1.1.28", "compiled"=>"2.8.0", "loaded"=>"2.8.0"}}

These values are time measurements. Lower is faster!

-- Benchmark --
  Small HTML fragment (757 bytes) x 1000
                                   total    single    rel
       Sanitize.fragment (strip)   1.077 (0.001077)     -
       Sanitize.fragment (prune)   1.077 (0.001077)  1.00x
                   Loofah :strip   0.524 (0.000524)  0.49x
                   Loofah :prune   0.522 (0.000522)  0.48x
                      HTMLFilter   0.876 (0.000876)  0.81x

  Large HTML fragment (33531 bytes) x 100
                                   total    single    rel
       Sanitize.fragment (strip)   3.281 (0.032813)     -
       Sanitize.fragment (prune)   3.316 (0.033160)  1.01x
                   Loofah :strip   3.950 (0.039502)  1.20x
                   Loofah :prune   4.050 (0.040504)  1.23x
                      HTMLFilter   7.437 (0.074365)  2.27x

  Small HTML document (25286 bytes) x 100
                                   total    single    rel
       Sanitize.document (strip)   1.648 (0.016479)     -
       Sanitize.document (prune)   1.639 (0.016390)  0.99x
                   Loofah :strip   1.855 (0.018551)  1.13x
                   Loofah :prune   1.841 (0.018407)  1.12x
               HTMLFilter ERROR!

  Medium HTML document (86685 bytes) x 100
                                   total    single    rel
       Sanitize.document (strip)   5.911 (0.059112)     -
       Sanitize.document (prune)   5.876 (0.058761)  0.99x
                   Loofah :strip   7.598 (0.075984)  1.29x
                   Loofah :prune   7.479 (0.074787)  1.27x
               HTMLFilter ERROR!

  Huge HTML document (7172510 bytes) x 5
                                   total    single    rel
       Sanitize.document (strip)  30.324 (6.064872)     -
       Sanitize.document (prune)  32.929 (6.585790)  1.09x
                   Loofah :strip  44.056 (8.811160)  1.45x
                   Loofah :prune  40.845 (8.168941)  1.35x
                      HTMLFilter  73.933 (14.786560)  2.44x
```

[htmlfilter]:https://github.com/rubyworks/htmlfilter
[loofah]:https://github.com/flavorjones/loofah
[sanitize]:https://github.com/rgrove/sanitize
