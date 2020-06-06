# Biased comparison of Ruby HTML sanitization libraries

This is a feature comparison of three widely used Ruby HTML sanitization
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

Feature                                               | [Sanitize 4.0.0][sanitize] | [Loofah 2.0.1][loofah] | [HTMLFilter 1.3.0][htmlfilter] |
----------------------------------------------------- |:--------------------------:|:----------------------:|:------------------------------:|
Actually parses HTML (not with regexes)               | ✓                          | ✓                      |                                |
HTML5-compliant parser                                | ✓                          |                        |                                |
Fixes up badly broken/malicious markup                | ✓                          | ✓                      |                                |
Fully configurable allowlists                         | ✓                          |                        | ✓                              |
Global attribute allowlist                            | ✓                          | ✓ (hard-coded)         |                                |
Element-specific attribute allowlist                  | ✓                          |                        | ✓                              |
Attribute-specific protocol allowlist                 | ✓                          |                        | ✓                              |
Supports HTML5 `data-` attributes                     | ✓                          | ✓ (hard-coded)         |                                |
Optionally escapes unsafe HTML instead of removing it |                            | ✓                      |                                |
Allows custom HTML manipulation (transformers)        | ✓                          | ✓                      |                                |
Built-in MathML support                               |                            | always enabled         |                                |
Built-in SVG support                                  |                            | always enabled         |                                |
Basic CSS sanitization                                | ✓                          | regex-based            | regex-based                    |
Advanced allowlist-based CSS sanitization             | ✓                          |                        |                                |

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

* Loofah's allowlist configuration is hard-coded and can only be customized by
  either editing its source or monkeypatching. Sanitize and HTMLFilter both have
  easily customizable allowlist configurations.

* Loofah has a single global allowlist for attributes, which it uses for all
  elements. HTMLFilter has per-element attribute allowlists, but provides no way
  to allowlist global attributes (i.e., attributes that should be allowed on any
  element, such as `class`). Sanitize supports both global and element-specific
  attribute allowlists.

* Sanitize and Loofah both support HTML5 data attributes. In Sanitize, data
  attributes can be enabled or disabled in either the global or element-specific
  allowlists. Loofah always allows data attributes on all elements, and this is
  not configurable. HTMLFilter does not support data attributes.

* Both Sanitize and Loofah allow you to write blocks or methods that can perform
  custom manipulation on HTML nodes as they're traversed. Sanitize calls them
  "transformers", whereas Loofah calls them "scrubbers". They're more or less
  equivalent in terms of functionality.

* Loofah has hard-coded allowlists for sanitizing MathML and SVG, which cannot
  be disabled via configuration. Sanitize does not provide built-in configs for
  sanitizing MathML or SVG, but it would be fairly trivial to add MathML and
  SVG elements and attributes to a custom allowlist config.

* Sanitize performs advanced allowlist-based CSS sanitization using
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

Benchmark                                  | [Sanitize 4.0.0][sanitize]             | [Loofah 2.0.1][loofah]               | [HTMLFilter 1.3.0][htmlfilter]
------------------------------------------ |:--------------------------------------:|:------------------------------------:|:------------------------------:
Small HTML fragment (757 bytes) x 1000     | 0.461s                                 | 0.595s                               | **0.413s**
Large HTML fragment (33,531 bytes) x 100   | **2.966s**                             | 4.618s                               | 3.054s
Small HTML document (25,286 bytes) x 100   | **1.629s**                             | 2.099s                               | _ERROR_
Medium HTML document (86,685 bytes) x 100  | **5.938s**                             | 8.531s                               | _ERROR_
Huge HTML document (7,172,510 bytes) x 5   | **28.682s**                            | 48.375s                              | 31.930s

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
Ruby version      : 2.2.2
Sanitize version  : 4.0.0
Loofah version    : 2.0.1
HTMLFilter version: 1.3.0

Nokogiri version: {"warnings"=>[], "nokogiri"=>"1.6.6.2", "ruby"=>{"version"=>"2.2.2", "platform"=>"x86_64-darwin14", "description"=>"ruby 2.2.2p95 (2015-04-13 revision 50295) [x86_64-darwin14]", "engine"=>"ruby"}, "libxml"=>{"binding"=>"extension", "source"=>"packaged", "libxml2_path"=>"/Users/rgrove/.rbenv/versions/2.2.2/lib/ruby/gems/2.2.0/gems/nokogiri-1.6.6.2/ports/x86_64-apple-darwin14.3.0/libxml2/2.9.2", "libxslt_path"=>"/Users/rgrove/.rbenv/versions/2.2.2/lib/ruby/gems/2.2.0/gems/nokogiri-1.6.6.2/ports/x86_64-apple-darwin14.3.0/libxslt/1.1.28", "libxml2_patches"=>["0001-Revert-Missing-initialization-for-the-catalog-module.patch", "0002-Fix-missing-entities-after-CVE-2014-3660-fix.patch"], "libxslt_patches"=>["0001-Adding-doc-update-related-to-1.1.28.patch", "0002-Fix-a-couple-of-places-where-f-printf-parameters-wer.patch", "0003-Initialize-pseudo-random-number-generator-with-curre.patch", "0004-EXSLT-function-str-replace-is-broken-as-is.patch", "0006-Fix-str-padding-to-work-with-UTF-8-strings.patch", "0007-Separate-function-for-predicate-matching-in-patterns.patch", "0008-Fix-direct-pattern-matching.patch", "0009-Fix-certain-patterns-with-predicates.patch", "0010-Fix-handling-of-UTF-8-strings-in-EXSLT-crypto-module.patch", "0013-Memory-leak-in-xsltCompileIdKeyPattern-error-path.patch", "0014-Fix-for-bug-436589.patch", "0015-Fix-mkdir-for-mingw.patch"], "compiled"=>"2.9.2", "loaded"=>"2.9.2"}}

These values are time measurements. Lower is faster!

-- Benchmark --
  Small HTML fragment (757 bytes) x 1000
                                   total    single    rel
               Sanitize#fragment   0.461 (0.000461)     -
               Sanitize.fragment   1.221 (0.001221)  2.65x
   Loofah.scrub_fragment (strip)   0.595 (0.000595)  1.29x
               HTMLFilter#filter   0.413 (0.000413)  0.90x

  Large HTML fragment (33531 bytes) x 100
                                   total    single    rel
               Sanitize#fragment   2.966 (0.029664)     -
               Sanitize.fragment   3.006 (0.030057)  1.01x
   Loofah.scrub_fragment (strip)   4.618 (0.046183)  1.56x
               HTMLFilter#filter   3.054 (0.030538)  1.03x

  Small HTML document (25286 bytes) x 100
                                   total    single    rel
               Sanitize#document   1.629 (0.016286)     -
               Sanitize.document   1.683 (0.016829)  1.03x
   Loofah.scrub_document (strip)   2.099 (0.020991)  1.29x
        HTMLFilter#filter ERROR!

  Medium HTML document (86685 bytes) x 100
                                   total    single    rel
               Sanitize#document   5.938 (0.059375)     -
               Sanitize.document   6.010 (0.060097)  1.01x
   Loofah.scrub_document (strip)   8.531 (0.085315)  1.44x
        HTMLFilter#filter ERROR!

  Huge HTML document (7172510 bytes) x 5
                                   total    single    rel
               Sanitize#document  28.682 (5.736398)     -
               Sanitize.document  29.550 (5.910002)  1.03x
   Loofah.scrub_document (strip)  48.375 (9.674925)  1.69x
               HTMLFilter#filter  31.930 (6.386075)  1.11x
```

[htmlfilter]:https://github.com/rubyworks/htmlfilter
[loofah]:https://github.com/flavorjones/loofah
[sanitize]:https://github.com/rgrove/sanitize
