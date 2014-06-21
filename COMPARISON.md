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

Based on [this synthetic benchmark][benchmark]. Smaller numbers are better (they
indicate faster completion).

[benchmark]:https://github.com/rgrove/sanitize/tree/master/benchmark

Benchmark                                  | [Sanitize 3.0.0][sanitize]             | [Loofah 2.0.0][loofah]               | [HTMLFilter 1.3.0][htmlfilter]
------------------------------------------ |:--------------------------------------:|:------------------------------------:|:------------------------------:
Small HTML fragment (757 bytes) x 1000     | **0.457s**                             | 0.569s                               | 0.975s
Large HTML fragment (33,531 bytes) x 100   | **3.708s**                             | 4.582s                               | 8.226s
Small HTML document (25,286 bytes) x 100   | **1.764s**                             | 2.026s                               | _ERROR_
Medium HTML document (86,685 bytes) x 100  | **6.714s**                             | 8.981s                               | _ERROR_
Huge HTML document (7,172,510 bytes) x 5   | **34.765s**                            | 41.162s                              | 75.168s

To run this benchmark yourself:

```
git clone https://github.com/rgrove/sanitize.git
cd sanitize
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
Ruby version      : 2.1.2
Sanitize version  : 3.0.0
Loofah version    : 2.0.0
HTMLFilter version: 1.3.0

Nokogiri version: {"warnings"=>[], "nokogiri"=>"1.6.2.1", "ruby"=>{"version"=>"2.1.2", "platform"=>"x86_64-darwin13.0", "description"=>"ruby 2.1.2p95 (2014-05-08 revision 45877) [x86_64-darwin13.0]", "engine"=>"ruby"}, "libxml"=>{"binding"=>"extension", "source"=>"packaged", "libxml2_path"=>"/Users/rgrove/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/gems/nokogiri-1.6.2.1/ports/x86_64-apple-darwin13.2.0/libxml2/2.8.0", "libxslt_path"=>"/Users/rgrove/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/gems/nokogiri-1.6.2.1/ports/x86_64-apple-darwin13.2.0/libxslt/1.1.28", "compiled"=>"2.8.0", "loaded"=>"2.8.0"}}

These values are time measurements. Lower is faster!

-- Benchmark --
  Small HTML fragment (757 bytes) x 1000
                                   total    single    rel
               Sanitize#fragment   0.457 (0.000457)     -
               Sanitize.fragment   1.127 (0.001127)  2.47x
   Loofah.scrub_fragment (strip)   0.569 (0.000569)  1.25x
               HTMLFilter#filter   0.975 (0.000975)  2.13x

  Large HTML fragment (33531 bytes) x 100
                                   total    single    rel
               Sanitize#fragment   3.708 (0.037075)     -
               Sanitize.fragment   3.720 (0.037201)  1.00x
   Loofah.scrub_fragment (strip)   4.582 (0.045825)  1.24x
               HTMLFilter#filter   8.226 (0.082255)  2.22x

  Small HTML document (25286 bytes) x 100
                                   total    single    rel
               Sanitize#document   1.764 (0.017638)     -
               Sanitize.document   1.838 (0.018382)  1.04x
   Loofah.scrub_document (strip)   2.026 (0.020263)  1.15x
        HTMLFilter#filter ERROR!

  Medium HTML document (86685 bytes) x 100
                                   total    single    rel
               Sanitize#document   6.714 (0.067136)     -
               Sanitize.document   6.804 (0.068041)  1.01x
   Loofah.scrub_document (strip)   8.981 (0.089805)  1.34x
        HTMLFilter#filter ERROR!

  Huge HTML document (7172510 bytes) x 5
                                   total    single    rel
               Sanitize#document  34.765 (6.953046)     -
               Sanitize.document  33.363 (6.672691)  0.96x
   Loofah.scrub_document (strip)  41.162 (8.232313)  1.18x
               HTMLFilter#filter  75.168 (15.033509)  2.16x
```

[htmlfilter]:https://github.com/rubyworks/htmlfilter
[loofah]:https://github.com/flavorjones/loofah
[sanitize]:https://github.com/rgrove/sanitize
