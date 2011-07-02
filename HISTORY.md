Sanitize History
================================================================================

Version 2.0.3 (2011-07-01)
--------------------------

 * Loosened the Nokogiri dependency to allow Nokogiri 1.5.x.


Version 2.0.2 (2011-05-21)
--------------------------

  * Fixed a bug in which a protocol like "java\script:" would be translated to
    "java%5Cscript:" and allowed through the filter when relative URLs were
    enabled. This didn't actually allow malicious code to run, but it is
    undesired behavior.


Version 2.0.1 (2011-03-16)
--------------------------

  * Updated the protocol regex to anchor at the beginning of the string rather
    than the beginning of a line. [Eaden McKee]


Version 2.0.0 (2011-01-15)
--------------------------

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
    elements to the whitelists for the basic and relaxed configs.
  * Added the `bdo`, `del`, `figcaption`, `figure`, `hgroup`, `ins`, `rp`, `rt`,
    `ruby`, and `wbr` elements to the whitelist for the relaxed config.
  * The `dir`, `lang`, and `title` attributes are now whitelisted for all
    elements in the relaxed config.
  * Bumped minimum Nokogiri version to 1.4.4 to avoid a bug in 1.4.2+
    (issue #315) that caused `</body></html>` to be appended to the CDATA inside
    unterminated script and style elements.


Version 1.2.1 (2010-04-20)
--------------------------

  * Added a `:remove_contents` config setting. If set to `true`, Sanitize will
    remove the contents of all non-whitelisted elements in addition to the
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


Version 1.2.0 (2010-01-17)
--------------------------

  * Requires Nokogiri ~> 1.4.1.
  * Added support for transformers, which allow you to filter and alter nodes
    using your own custom logic, on top of (or instead of) Sanitize's core
    filter. See the README for details and examples.
  * Added `Sanitize.clean_node!`, which sanitizes a `Nokogiri::XML::Node` and
    all its children.
  * Added elements `<h1>` through `<h6>` to the Relaxed whitelist. [Suggested by
    David Reese]


Version 1.1.0 (2009-10-11)
--------------------------

  * Migrated from Hpricot to Nokogiri. Requires libxml2 >= 2.7.2 [Adam Hooper]
  * Added an `:output` config setting to allow the output format to be
    specified. Supported formats are `:xhtml` (the default) and `:html` (which
    outputs HTML4).
  * Changed protocol regex to ensure Sanitize doesn't kill URLs with colons in 
    path segments. [Peter Cooper]


Version 1.0.8 (2009-04-23)
--------------------------

  * Added a workaround for an Hpricot bug that prevents attribute names from
    being downcased in recent versions of Hpricot. This was exploitable to
    prevent non-whitelisted protocols from being cleaned. [Reported by Ben
    Wanicur]


Version 1.0.7 (2009-04-11)
--------------------------

  * Requires Hpricot 0.8.1+, which is finally compatible with Ruby 1.9.1.
  * Fixed a bug that caused named character entities containing digits (like
    `&sup2;`) to be escaped when they shouldn't have been. [Reported by
    Sebastian Steinmetz]


Version 1.0.6 (2009-02-23)
--------------------------

  * Removed htmlentities gem dependency.
  * Existing well-formed character entity references in the input string are now
    preserved rather than being decoded and re-encoded.
  * The `'` character is now encoded as `&#39;` instead of `&apos;` to prevent
    problems in IE6.
  * You can now specify the symbol `:all` in place of an element name in the
    attributes config hash to allow certain attributes on all elements. [Thanks
    to Mutwin Kraus]


Version 1.0.5 (2009-02-05)
--------------------------

  * Fixed a bug introduced in version 1.0.3 that prevented non-whitelisted
    protocols from being cleaned when relative URLs were allowed. [Reported by
    Dev Purkayastha]
  * Fixed "undefined method `parent='" exceptions caused by parser changes in
    edge Hpricot.


Version 1.0.4 (2009-01-16)
--------------------------

  * Fixed a bug that made it possible to sneak a non-whitelisted element through
    by repeating it several times in a row. All versions of Sanitize prior to
    1.0.4 are vulnerable. [Reported by Cristobal]


Version 1.0.3 (2009-01-15)
--------------------------

  * Fixed a bug whereby incomplete Unicode or hex entities could be used to
    prevent non-whitelisted protocols from being cleaned. Since IE6 and Opera
    still decode the incomplete entities, users of those browsers may be
    vulnerable to malicious script injection on websites using versions of
    Sanitize prior to 1.0.3.


Version 1.0.2 (2009-01-04)
--------------------------

  * Fixed a bug that caused an exception to be thrown when parsing a valueless
    attribute that's expected to contain a URL.


Version 1.0.1 (2009-01-01)
--------------------------

  * You can now specify `:relative` in a protocol config array to allow
    attributes containing relative URLs with no protocol. The Basic and Relaxed
    configs have been updated to allow relative URLs.
  * Added a workaround for an Hpricot bug that causes HTML entities for
    non-ASCII characters to be replaced by question marks, and all other
    entities to be destructively decoded.


Version 1.0.0 (2008-12-25)
--------------------------

  * First release.
