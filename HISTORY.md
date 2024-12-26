# Sanitize History

## Unreleased

### Potentially Breaking Changes

* Sanitize now requires Nokogiri 1.16.8 or higher.

### Features

* Added the `-webkit-text-fill-color` CSS property to the relaxed config. [@radar - #244][244]

[244]:https://github.com/rgrove/sanitize/pull/244

## 6.1.3 (2024-08-14)

### Bug Fixes

* The CSS URL protocol allowlist is now enforced on the nonstandard `-webkit-image-set` CSS function. [@ltk - #242][242]

[242]:https://github.com/rgrove/sanitize/pull/242

## 6.1.2 (2024-07-27)

### Bug Fixes

* The CSS URL protocol allowlist is now properly enforced in [CSS Images Module Level 4](https://drafts.csswg.org/css-images-4/) `image` and `image-set` functions. [@ltk - #240][240]

[240]:https://github.com/rgrove/sanitize/pull/240

## 6.1.1 (2024-06-12)

### Bug Fixes

* Proactively fixed a compatibility issue with libxml >= 2.13.0 (which will be used in an upcoming version of Nokogiri) that caused HTML doctype sanitization to fail. [@flavorjones - #238][238]

[238]:https://github.com/rgrove/sanitize/pull/238

## 6.1.0 (2023-09-14)

### Features

* Added the `text-decoration-skip-ink` and `text-decoration-thickness` CSS properties to the relaxed config. [@martineriksson - #228][228]

[228]:https://github.com/rgrove/sanitize/pull/228

## 6.0.2 (2023-07-06)

### Bug Fixes

* CVE-2023-36823: Fixed an HTML+CSS sanitization bypass that could allow XSS
  (cross-site scripting). This issue affects Sanitize versions 3.0.0 through
  6.0.1.

  When using Sanitize's relaxed config or a custom config that allows `<style>`
  elements and one or more CSS at-rules, carefully crafted input could be used
  to sneak arbitrary HTML through Sanitize.

  See the following security advisory for additional details:
  [GHSA-f5ww-cq3m-q3g7](https://github.com/rgrove/sanitize/security/advisories/GHSA-f5ww-cq3m-q3g7)

  Thanks to @cure53 for finding this issue.

## 6.0.1 (2023-01-27)

### Bug Fixes

* Sanitize now always removes `<noscript>` elements and their contents, even
  when `noscript` is in the allowlist.

  This fixes a sanitization bypass that could occur when `noscript` was allowed
  by a custom allowlist. In this scenario, carefully crafted input could sneak
  arbitrary HTML through Sanitize, potentially enabling an XSS (cross-site
  scripting) attack.

  Sanitize's default configs don't allow `<noscript>` elements and are not
  vulnerable. This issue only affects users who are using a custom config that
  adds `noscript` to the element allowlist.

  The root cause of this issue is that HTML parsing rules treat the contents of
  a `<noscript>` element differently depending on whether scripting is enabled
  in the user agent. Nokogiri doesn't support scripting so it follows the
  "scripting disabled" rules, but a web browser with scripting enabled will
  follow the "scripting enabled" rules. This means that Sanitize can't reliably
  make the contents of a `<noscript>` element safe for scripting enabled
  browsers, so the safest thing to do is to remove the element and its contents
  entirely.

  See the following security advisory for additional details:
  [GHSA-fw3g-2h3j-qmm7](https://github.com/rgrove/sanitize/security/advisories/GHSA-fw3g-2h3j-qmm7)

  Thanks to David Klein from [TU Braunschweig](https://www.tu-braunschweig.de/en/ias)
  (@leeN) for reporting this issue.

* Fixed an edge case in which the contents of an "unescaped text" element (such
  as `<noembed>` or `<xmp>`) were not properly escaped if that element was
  allowlisted and was also inside an allowlisted `<math>` or `<svg>` element.

  The only way to encounter this situation was to ignore multiple warnings in
  the readme and create a custom config that allowlisted all the elements
  involved, including `<math>` or `<svg>`. If you're using a default config or
  if you heeded the warnings about MathML and SVG not being supported, you're
  not affected by this issue.

  Please let this be a reminder that Sanitize cannot safely sanitize MathML or
  SVG content and does not support this use case. The default configs don't
  allow MathML or SVG elements, and allowlisting MathML or SVG elements in a
  custom config may create a security vulnerability in your application.

  Documentation has been updated to add more warnings and to make the existing
  warnings about this more prominent.

  Thanks to David Klein from [TU Braunschweig](https://www.tu-braunschweig.de/en/ias)
  (@leeN) for reporting this issue.

## 6.0.0 (2021-08-03)

### Potentially Breaking Changes

* Ruby 2.5.0 is now the oldest officially supported Ruby version.

* Sanitize now requires Nokogiri 1.12.0 or higher, which includes Nokogumbo.
  The separate dependency on Nokogumbo has been removed. [@lis2 - #211][211]

[211]:https://github.com/rgrove/sanitize/pull/211

## 5.2.3 (2021-01-11)

### Bug Fixes

* Ensure protocol sanitization is applied to data attributes.
  [@ccutrer - #207][207]

[207]:https://github.com/rgrove/sanitize/pull/207

## 5.2.2 (2021-01-06)

### Bug Fixes

* Fixed a deprecation warning in Ruby 2.7+ when using keyword arguments in a
  custom transformer. [@mscrivo - #206][206]

[206]:https://github.com/rgrove/sanitize/pull/206

## 5.2.1 (2020-06-16)

### Bug Fixes

* Fixed an HTML sanitization bypass that could allow XSS. This issue affects
  Sanitize versions 3.0.0 through 5.2.0.

  When HTML was sanitized using the "relaxed" config or a custom config that
  allows certain elements, some content in a `<math>` or `<svg>` element may not
  have beeen sanitized correctly even if `math` and `svg` were not in the
  allowlist. This could allow carefully crafted input to sneak arbitrary HTML
  through Sanitize, potentially enabling an XSS (cross-site scripting) attack.

  You are likely to be vulnerable to this issue if you use Sanitize's relaxed
  config or a custom config that allows one or more of the following HTML
  elements:

    -   `iframe`
    -   `math`
    -   `noembed`
    -   `noframes`
    -   `noscript`
    -   `plaintext`
    -   `script`
    -   `style`
    -   `svg`
    -   `xmp`

  See the security advisory for more details, including a workaround if you're
  not able to upgrade: [GHSA-p4x4-rw2p-8j8m]

  Many thanks to Michał Bentkowski of Securitum for reporting this issue and
  helping to verify the fix.

[GHSA-p4x4-rw2p-8j8m]:https://github.com/rgrove/sanitize/security/advisories/GHSA-p4x4-rw2p-8j8m

## 5.2.0 (2020-06-06)

### Changes

* The term "whitelist" has been replaced with "allowlist" throughout Sanitize's
  source and documentation.

  While the etymology of "whitelist" may not be explicitly racist in origin or
  intent, there are inherent racial connotations in the implication that white
  is good and black (as in "blacklist") is not.

  This is a change I should have made long ago, and I apologize for not making
  it sooner.

* In transformer input, the `:is_whitelisted` and `:node_whitelist` keys are now
  deprecated. New `:is_allowlisted` and `:node_allowlist` keys have been added.
  The old keys will continue to work in order to avoid breaking existing code,
  but they are no longer documented and may be removed in a future semver major
  release.

## 5.1.0 (2019-09-07)

### Features

* Added a `:parser_options` config hash, which makes it possible to pass custom
  parsing options to Nokogumbo. [@austin-wang - #194][194]

### Bug Fixes

* Non-characters and non-whitespace control characters are now stripped from
  HTML input before parsing to comply with the HTML Standard's [preprocessing
  guidelines][html-preprocessing]. Prior to this Sanitize had adhered to [older
  W3C guidelines][unicode-xml] that have since been withdrawn. [#179][179]

[179]:https://github.com/rgrove/sanitize/issues/179
[194]:https://github.com/rgrove/sanitize/pull/194
[html-preprocessing]:https://html.spec.whatwg.org/multipage/parsing.html#preprocessing-the-input-stream
[unicode-xml]:https://www.w3.org/TR/unicode-xml/

## 5.0.0 (2018-10-14)

For most users, upgrading from 4.x shouldn't require any changes. However, the
minimum required Ruby version has changed, and Sanitize 5.x's HTML output may
differ in some small ways from 4.x's output. If this matters to you, please
review the changes below carefully.

### Potentially Breaking Changes

* Ruby 2.3.0 is now the oldest officially supported Ruby version. Sanitize may
  work in older 2.x Rubies, but they aren't actively tested. Sanitize definitely
  no longer works in Ruby 1.9.x.

* Upgraded to Nokogumbo 2.x, which fixes various bugs and adds
  standard-compliant HTML serialization. [@stevecheckoway - #189][189]

* Children of the following elements are now removed by default when these
  elements are removed, rather than being preserved and escaped:

  - `iframe`
  - `noembed`
  - `noframes`
  - `noscript`
  - `script`
  - `style`

* Children of allowlisted `iframe` elements are now always removed. In modern
  HTML, `iframe` elements should never have children. In HTML 4 and earlier
  `iframe` elements were allowed to contain fallback content for legacy
  browsers, but it's been almost two decades since that was useful.

* Fixed a bug that caused `:remove_contents` to behave as if it were set to
  `true` when it was actually an Array.

[189]:https://github.com/rgrove/sanitize/pull/189

## 4.6.6 (2018-07-23)

* Improved performance and memory usage by optimizing `Sanitize#transform_node!`
  [@stanhu - #183][183]

[183]:https://github.com/rgrove/sanitize/pull/183

## 4.6.5 (2018-05-16)

* Improved performance slightly by tweaking the order of built-in transformers.
  [@rafbm - #180][180]

[180]:https://github.com/rgrove/sanitize/pull/180

## 4.6.4 (2018-03-20)

* Fixed: A change introduced in 4.6.2 broke certain transformers that relied on
  being able to mutate the name of an HTML node. That change has been reverted
  and a test has been added to cover this case. [@zetter - #177][177]

[177]:https://github.com/rgrove/sanitize/issues/177

## 4.6.3 (2018-03-19)

* [CVE-2018-3740][176]: Fixed an HTML injection vulnerability that could allow
  XSS.

  When Sanitize <= 4.6.2 is used in combination with libxml2 >= 2.9.2, a
  specially crafted HTML fragment can cause libxml2 to generate improperly
  escaped output, allowing non-allowlisted attributes to be used on allowlisted
  elements.

  Sanitize now performs additional escaping on affected attributes to prevent
  this.

  Many thanks to the Shopify Application Security Team for responsibly reporting
  this issue.

[176]:https://github.com/rgrove/sanitize/issues/176

## 4.6.2 (2018-03-19)

* Reduced string allocations to optimize memory usage. [@janklimo - #175][175]

[175]:https://github.com/rgrove/sanitize/pull/175

## 4.6.1 (2018-03-15)

* Added support for frozen string literals in Ruby 2.4+.
  [@flavorjones - #174][174]

[174]:https://github.com/rgrove/sanitize/pull/174

## 4.6.0 (2018-01-29)

* Loosened the Nokogumbo dependency to allow installing semver-compatible
  versions greater than or equal to v1.4. [@rafbm - #171][171]

[171]:https://github.com/rgrove/sanitize/pull/171

## 4.5.0 (2017-06-04)

* Added SVG-related CSS properties to the relaxed config. See [the diff][161]
  for the full list of added properties. [@louim - #161][161]

* Fixed: Sanitize now strips null bytes (`\u0000`) before passing input to
  Nokogumbo, since they can cause recent versions to crash with a failed
  assertion in the Gumbo parser.

[161]:https://github.com/rgrove/sanitize/pull/161

## 4.4.0 (2016-09-29)

* Added `srcset` to the attribute allowlist for `img` elements in the relaxed
  config. [@ejtttje - #156][156]

[156]:https://github.com/rgrove/sanitize/pull/156


## 4.3.0 (2016-09-20)

* Methods can now be used as transformers. [@Skipants - #155][155]

[155]:https://github.com/rgrove/sanitize/pull/155


## 4.2.0 (2016-08-22)

* Added `-webkit-font-smoothing` to the relaxed CSS config. [@louim - #154][154]

* Fixed: Nokogumbo >=1.4.9 changed its behavior in a way that allowed invalid
  doctypes (like `<!DOCTYPE nonsense>`) when the `:allow_doctype` config setting
  was `true`. Invalid doctypes are now coerced to valid ones as they were prior
  to this Nokogumbo change.

[154]:https://github.com/rgrove/sanitize/pull/154


## 4.1.0 (2016-06-17)

* Added a new CSS config setting, `:import_url_validator`. This is a Proc or
  other callable object that will be called with each `@import` URL, and should
  return `true` to allow the URL or `false` to remove it. [@nikz - #153][153]

[153]:https://github.com/rgrove/sanitize/pull/153/


## 4.0.1 (2015-12-09)

* Unpinned the Nokogumbo dependency. [@rubys - #141][141]

[141]:https://github.com/rgrove/sanitize/pull/141


## 4.0.0 (2015-04-20)

### Potentially breaking changes

* Added two new CSS config settings, `:at_rules_with_properties` and
  `:at_rules_with_styles`. These allow you to define which at-rules should be
  allowed to contain properties and which should be allowed to contain style
  rules. Previously this was hard-coded internally. [#111][111]

  The previous `:at_rules` setting still exists, and defines at-rules that may
  not have associated blocks, such as `@import`. If you have a custom config
  that contains an `:at_rules` setting, you may need to move rules can have
  blocks to either `:at_rules_with_properties` or `:at_rules_with_styles`.

  See Sanitize's relaxed config for an example.

### Other changes

* Added full support for CSS `@page` rules in the relaxed config, including
  support for all page-margin box rules (such as `@top-left`, `@bottom-center`,
  etc.)

* Added the following CSS at-rules to the relaxed config:

    - `@-moz-keyframes`
    - `@-o-keyframes`
    - `@-webkit-keyframes`
    - `@document`

* Added a whole bunch of CSS properties to the relaxed config. View the complete
  list [here](https://gist.github.com/rgrove/044cc7e9a5b44f583c05).

* Small performance improvements.

* Fixed: Upgraded Crass to 1.0.2 to pick up a fix that affected the parsing of
  CSS `@page` rules.

[111]:https://github.com/rgrove/sanitize/issues/111


## 3.1.2 (2015-02-22)

* Fixed: Deleting a node in a custom transformer could trigger a memory leak
  in Nokogiri if that node's children were later reparented, which the built-in
  CleanElement transformer did by default. The CleanElement transformer is now
  careful not to reparent the children of deleted nodes. [#129][129]

[129]:https://github.com/rgrove/sanitize/issues/129


## 3.1.1 (2015-02-04)

* Fixed: `#document` and `#fragment` failed on frozen strings, and could
  unintentionally modify unfrozen strings if they used an encoding other than
  UTF-8 or if they contained characters not allowed in HTML.
  [@AnchorCat - #128][128]

[128]:https://github.com/rgrove/sanitize/pull/128


## 3.1.0 (2014-12-22)

* Added the following CSS properties to the relaxed config. [@ehudc - #120][120]

    - `-moz-text-size-adjust`
    - `-ms-text-size-adjust`
    - `-webkit-text-size-adjust`
    - `text-size-adjust`

* Updated Nokogumbo to 1.2.0 to pick up a fix for a Gumbo bug where the
  entity `&AElig;` left its semicolon behind when it was converted to a
  character during parsing. [#119][119]

[119]:https://github.com/rgrove/sanitize/issues/119
[120]:https://github.com/rgrove/sanitize/pull/120


## 3.0.4 (2014-12-12)

* Fixed: Harmless whitespace preceding a URL protocol (such as " http://")
  caused the URL to be removed even when the protocol was allowlisted.
  [@benubois - #126][126]

[126]:https://github.com/rgrove/sanitize/pull/126


## 3.0.3 (2014-10-29)

* Fixed: Some CSS selectors weren't parsed correctly inside the body of a
  `@media` block, causing them to be removed even when allowlist rules should
  have allowed them to remain. [#121][121]

[121]:https://github.com/rgrove/sanitize/issues/121


## 3.0.2 (2014-09-02)

* Updated Nokogumbo to 1.1.12, because 1.1.11 silently reverted the change we
  were trying to pick up in the last release. Now issue [#114][114] is
  _actually_ fixed.


## 3.0.1 (2014-09-02)

* Updated Nokogumbo to 1.1.11 to pick up a fix for a Gumbo bug in which certain
  HTML character entities, such as `&Ouml;`, were parsed incorrectly, leaving
  the semicolon behind in the output. [#114][114]

[114]:https://github.com/rgrove/sanitize/issues/114


## 3.0.0 (2014-06-21)

As of this version, Sanitize adheres strictly to the [SemVer 2.0.0][semver]
versioning standard. This release contains API and output changes that are
incompatible with previous releases, as indicated by the major version
increment.

[semver]:http://semver.org/

### Backwards-incompatible changes

* HTML is now parsed using Google's Gumbo HTML5 parser, which adheres to the
  HTML5 parsing spec and behaves much more like modern browser parsers than the
  previous libxml2-based parser. As a result, HTML output may differ from that
  of previous versions of Sanitize.

* All transformers now traverse the document from the top down, starting with
  the first node, then its first child, and so on. The `:transformers_breadth`
  config has been removed, and old bottom-up transformers (the previous default)
  may need to be rewritten.

* Sanitize's built-in configs are now deeply frozen to prevent people from
  modifying them (either accidentally or maliciously). To customize a built-in
  config, create a new copy using `Sanitize::Config.merge()`, like so:

```ruby
Sanitize.fragment(html, Sanitize::Config.merge(Sanitize::Config::BASIC,
  :elements        => Sanitize::Config::BASIC[:elements] + ['div', 'table'],
  :remove_contents => true
))
```

* The `clean!` and `clean_document!` methods were removed, since they weren't
  useful and tended to confuse people.

* The `clean` method was renamed to `fragment` to more clearly indicate that its
  intended use is to sanitize an HTML fragment.

* The `clean_document` method was renamed to `document`.

* The `clean_node!` method was renamed to `node!`.

* The `document` method now raises a `Sanitize::Error` if the `<html>` element
  isn't allowlisted, rather than a `RuntimeError`. This error is also now raised
  regardless of the `:remove_contents` config setting.

* The `:output` config has been removed. Output is now always HTML, not XHTML.

* The `:output_encoding` config has been removed. Output is now always UTF-8.

### Other changes

* Added advanced CSS sanitization support using [Crass][crass], which is fully
  compliant with the CSS Syntax Module Level 3 parsing spec. The contents of
  allowlisted `<style>` elements and `style` attributes in HTML will be
  sanitized as CSS, or you can use the `Sanitize::CSS` class to manually
  sanitize CSS stylesheets or properties.

* Added an `:allow_doctype` setting. When `true`, well-formed doctype
  definitions will be allowed in documents. When `false` (the default), doctype
  definitions will be removed from documents. Doctype definitions are never
  allowed in fragments, regardless of this setting.

* Added the following elements to the relaxed config, in addition to various
  attributes: `article`, `aside`, `body`, `data`, `div`, `footer`, `head`,
  `header`, `html`, `main`, `nav`, `section`, `span`, `style`, `title`.

* The `:whitespace_elements` config is now a Hash, and allows you to specify the
  text that should be inserted before and after these elements when they're
  removed. The old-style Array-based config value is still supported for
  backwards compatibility. [@alperkokmen - #94][94]

* Unsuitable Unicode characters are now removed from HTML before it's parsed.
  [#106][106]

* Fixed: Non-tag brackets in input like `"1 > 2 and 2 < 1"` are now parsed and
  escaped correctly in accordance with the HTML5 spec, becoming
  `"1 &gt; 2 and 2 &lt; 1"`. [#83][83]

* Fixed: Siblings added after the current node during traversal are now
  also traversed. In previous versions they were simply skipped. [#91][91]

* Fixed: Nokogiri has been smacked and instructed to stop adding newlines after
  certain elements, because if people wanted newlines there they'd have put them
  there, dammit. [#103][103]

* Fixed: Added a workaround for a libxml2 bug that caused an undesired
  content-type meta tag to be added to all documents with `<head>` elements.
  [Nokogiri #1008][n1008]

[crass]:https://github.com/rgrove/crass
[83]:https://github.com/rgrove/sanitize/issues/83
[91]:https://github.com/rgrove/sanitize/issues/91
[94]:https://github.com/rgrove/sanitize/pull/94/
[103]:https://github.com/rgrove/sanitize/issues/103
[106]:https://github.com/rgrove/sanitize/issues/106
[n1008]:https://github.com/sparklemotion/nokogiri/issues/1008


## 2.1.1 (2018-09-30)

* [CVE-2018-3740][176]: Fixed an HTML injection vulnerability that could allow
  XSS (backported from Sanitize 4.6.3). [@dometto - #188][188]

  When Sanitize <= 2.1.0 is used in combination with libxml2 >= 2.9.2, a
  specially crafted HTML fragment can cause libxml2 to generate improperly
  escaped output, allowing non-allowlisted attributes to be used on allowlisted
  elements.

  Sanitize now performs additional escaping on affected attributes to prevent
  this.

  Many thanks to the Shopify Application Security Team for responsibly reporting
  this issue.

[176]:https://github.com/rgrove/sanitize/issues/176
[188]:https://github.com/rgrove/sanitize/pull/188


## 2.1.0 (2014-01-13)

* Added support for allowlisting arbitrary HTML5 `data-*` attributes. Use the
  symbol `:data` instead of an attribute name in the `:attributes` config to
  indicate that arbitrary data attributes should be allowed on an element.

* Added the following elements to the relaxed config: `address`, `bdi`, `hr`,
  and `summary`.

* Fixed: A colon (`:`) character in a URL fragment identifier such as `#foo:1`
  was incorrectly treated as a protocol delimiter. [@heathd - #87][87]

[87]:https://github.com/rgrove/sanitize/pull/87


## 2.0.6 (2013-07-10)

* Fixed: Version 2.0.5 inadvertently included some work-in-progress changes that
  shouldn't have made their way into the master branch. This is what happens
  when I release before coffee instead of after.


## 2.0.5 (2013-07-10)

* Loosened the Nokogiri dependency back to >= 1.4.4 to allow Sanitize to coexist
  in newer Rubies with other libraries that restrict Nokogiri to 1.5.x for 1.8.7
  compatibility. Sanitize still no longer supports 1.8.7, but this should make
  life easier for people who need those other libs.


## 2.0.4 (2013-06-12)

* Added `Sanitize.clean_document`, which sanitizes a full HTML document rather
  than just a fragment. [Ben Anderson]

* Nokogiri dependency bumped to 1.6.x.

* Dropped support for Ruby versions older than 1.9.2.


## 2.0.3 (2011-07-01)

* Loosened the Nokogiri dependency to allow Nokogiri 1.5.x.


## 2.0.2 (2011-05-21)

* Fixed a bug in which a protocol like "java\script:" would be translated to
  "java%5Cscript:" and allowed through the filter when relative URLs were
  enabled. This didn't actually allow malicious code to run, but it is
  undesired behavior.


## 2.0.1 (2011-03-16)

* Updated the protocol regex to anchor at the beginning of the string rather
  than the beginning of a line. [Eaden McKee]


## 2.0.0 (2011-01-15)

* The environment data passed into transformers and the return values expected
  from transformers have changed. Old transformers will need to be updated.
  See the README for details.

* Transformers now receive nodes of all types, not just element nodes.

* Sanitize's own core filtering logic is now implemented as a set of always-on
  transformers.

* The default value for the `:output` config is now `:html`. Previously it was
  `:xhtml`.

* Added a `:whitespace_elements` config, which specifies elements (such as
  `<br>` and `<p>`) that should be replaced with whitespace when removed in
  order to preserve readability. See the README for the default list of
  elements that will be replaced with whitespace when removed.

* Added a `:transformers_breadth` config, which may be used to specify
  transformers that should traverse nodes in a breadth-first mode rather than
  the default depth-first mode.

* Added the `abbr`, `dfn`, `kbd`, `mark`, `s`, `samp`, `time`, and `var`
  elements to the allowlists for the basic and relaxed configs.

* Added the `bdo`, `del`, `figcaption`, `figure`, `hgroup`, `ins`, `rp`, `rt`,
  `ruby`, and `wbr` elements to the allowlist for the relaxed config.

* The `dir`, `lang`, and `title` attributes are now allowlisted for all
  elements in the relaxed config.

* Bumped minimum Nokogiri version to 1.4.4 to avoid a bug in 1.4.2+
  (issue #315) that caused `</body></html>` to be appended to the CDATA inside
  unterminated script and style elements.


## 1.2.1 (2010-04-20)

* Added a `:remove_contents` config setting. If set to `true`, Sanitize will
  remove the contents of all non-allowlisted elements in addition to the
  elements themselves. If set to an array of element names, Sanitize will
  remove the contents of only those elements (when filtered), and leave the
  contents of other filtered elements. [Thanks to Rafael Souza for the array
  option]

* Added an `:output_encoding` config setting to allow the character encoding
  for HTML output to be specified. The default is utf-8.

* The environment hash passed into transformers now includes a `:node_name`
  item containing the lowercase name of the current HTML node (e.g. "div").

* Returning anything other than a Hash or nil from a transformer will now
  raise a meaningful `Sanitize::Error` exception rather than an unintended
  `NameError`.


## 1.2.0 (2010-01-17)

* Requires Nokogiri ~> 1.4.1.

* Added support for transformers, which allow you to filter and alter nodes
  using your own custom logic, on top of (or instead of) Sanitize's core
  filter. See the README for details and examples.

* Added `Sanitize.clean_node!`, which sanitizes a `Nokogiri::XML::Node` and
  all its children.

* Added elements `<h1>` through `<h6>` to the Relaxed allowlist. [Suggested by
  David Reese]


## 1.1.0 (2009-10-11)

* Migrated from Hpricot to Nokogiri. Requires libxml2 >= 2.7.2 [Adam Hooper]

* Added an `:output` config setting to allow the output format to be
  specified. Supported formats are `:xhtml` (the default) and `:html` (which
  outputs HTML4).

* Changed protocol regex to ensure Sanitize doesn't kill URLs with colons in
  path segments. [Peter Cooper]


## 1.0.8 (2009-04-23)

* Added a workaround for an Hpricot bug that prevents attribute names from
  being downcased in recent versions of Hpricot. This was exploitable to
  prevent non-allowlisted protocols from being cleaned. [Reported by Ben
  Wanicur]


## 1.0.7 (2009-04-11)

* Requires Hpricot 0.8.1+, which is finally compatible with Ruby 1.9.1.

* Fixed a bug that caused named character entities containing digits (like
  `&sup2;`) to be escaped when they shouldn't have been. [Reported by
  Sebastian Steinmetz]


## 1.0.6 (2009-02-23)

* Removed htmlentities gem dependency.

* Existing well-formed character entity references in the input string are now
  preserved rather than being decoded and re-encoded.

* The `'` character is now encoded as `&#39;` instead of `&apos;` to prevent
  problems in IE6.

* You can now specify the symbol `:all` in place of an element name in the
  attributes config hash to allow certain attributes on all elements. [Thanks
  to Mutwin Kraus]


## 1.0.5 (2009-02-05)

* Fixed a bug introduced in version 1.0.3 that prevented non-allowlisted
  protocols from being cleaned when relative URLs were allowed. [Reported by
  Dev Purkayastha]

* Fixed "undefined method `parent='" exceptions caused by parser changes in
  edge Hpricot.


## 1.0.4 (2009-01-16)

* Fixed a bug that made it possible to sneak a non-allowlisted element through
  by repeating it several times in a row. All versions of Sanitize prior to
  1.0.4 are vulnerable. [Reported by Cristobal]


## 1.0.3 (2009-01-15)

* Fixed a bug whereby incomplete Unicode or hex entities could be used to
  prevent non-allowlisted protocols from being cleaned. Since IE6 and Opera
  still decode the incomplete entities, users of those browsers may be
  vulnerable to malicious script injection on websites using versions of
  Sanitize prior to 1.0.3.


## 1.0.2 (2009-01-04)

* Fixed a bug that caused an exception to be thrown when parsing a valueless
  attribute that's expected to contain a URL.


## 1.0.1 (2009-01-01)

* You can now specify `:relative` in a protocol config array to allow
  attributes containing relative URLs with no protocol. The Basic and Relaxed
  configs have been updated to allow relative URLs.

* Added a workaround for an Hpricot bug that causes HTML entities for
  non-ASCII characters to be replaced by question marks, and all other
  entities to be destructively decoded.


## 1.0.0 (2008-12-25)

* First release.
