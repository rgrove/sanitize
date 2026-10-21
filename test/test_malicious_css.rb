# frozen_string_literal: true

require_relative "common"

# Miscellaneous attempts to sneak maliciously crafted CSS past Sanitize. Some of
# these are courtesy of (or inspired by) the OWASP XSS Filter Evasion Cheat
# Sheet.
#
# https://www.owasp.org/index.php/XSS_Filter_Evasion_Cheat_Sheet

describe "Malicious CSS" do
  make_my_diffs_pretty!
  parallelize_me!

  before do
    @s = Sanitize::CSS.new(Sanitize::Config::RELAXED)
  end

  it "should not be possible to inject an expression by munging it with a comment" do
    _(@s.properties(%[width:expr/*XSS*/ession(alert('XSS'))]))
      .must_equal ""

    _(@s.properties(%[width:ex/*XSS*//*/*/pression(alert("XSS"))]))
      .must_equal ""
  end

  it "should not be possible to inject an expression by munging it with a newline" do
    _(@s.properties(%[width:\nexpression(alert('XSS'));]))
      .must_equal ""
  end

  it "should not allow the javascript protocol" do
    _(@s.properties(%[background-image:url("javascript:alert('XSS')");]))
      .must_equal ""

    _(Sanitize.fragment(%[<div style="background-image: url(&#1;javascript:alert('XSS'))">],
      Sanitize::Config::RELAXED)).must_equal "<div></div>"
  end

  it "should not allow behaviors" do
    _(@s.properties(%[behavior: url(xss.htc);])).must_equal ""
  end

  describe "sanitization bypass via bad URL tokenization differential" do
    # Older versions of Crass didn't terminate a bad URL at a `)` that followed
    # an escaped backslash, but browsers do. These tests ensure that CSS hidden
    # inside a bad URL can't be smuggled past Sanitize regardless of how the
    # installed version of Crass tokenizes it.
    #
    # `bs` is a single literal backslash, used to avoid escaping ambiguity.
    bs = "\\"

    before do
      @config = {css: {properties: %w[color], protocols: []}}
    end

    it "should not allow declarations to be smuggled out of a [] block" do
      css = %[color:[url(x"#{bs * 2})]; position:fixed; x:)]
      result = Sanitize::CSS.properties(css, @config)

      refute_includes(result, "position")
      refute_includes(result, "url(")
    end

    it "should not allow declarations to be smuggled out of a () block" do
      css = %[color:(url(x"#{bs * 2})); position:fixed; x:)]
      result = Sanitize::CSS.properties(css, @config)

      refute_includes(result, "position")
      refute_includes(result, "url(")
    end

    it "should not allow declarations to be smuggled out of a style attribute" do
      html = %[<p style='color:[url(x"#{bs * 2})]; position:fixed; x:)'>hi</p>]
      result = Sanitize.fragment(html, Sanitize::Config.merge(Sanitize::Config::RELAXED, @config))

      refute_includes(result, "position")
      refute_includes(result, "url(")
    end

    it "should not allow rules to be smuggled out of a selector" do
      css = %[a url(x"#{bs * 2}){} *{position:fixed;background:url(https://example.com/x)} b){color:red}]
      result = Sanitize::CSS.stylesheet(css, @config)

      refute_includes(result, "position")
      refute_includes(result, "url(")
    end

    it "should not allow rules to be smuggled out of a nested selector function" do
      css = %[a:not(url(x"#{bs * 2})){} *{position:fixed} x)){color:red}]
      result = Sanitize::CSS.stylesheet(css, @config)

      refute_includes(result, "position")
      refute_includes(result, "url(")
    end

    it "should not allow an @import to be smuggled out of a selector" do
      css = %[a url(x"#{bs * 2}){} @import url(https://example.com/x.css); b){color:red}]
      result = Sanitize::CSS.stylesheet(css, Sanitize::Config::RELAXED)

      refute_includes(result, "@import")
      refute_includes(result, "url(")
    end

    it "should not allow rules to be smuggled out of an at-rule prelude" do
      css = %[@media url(x"#{bs * 2}){} *{position:fixed} x){} a{color:red}]
      config = {css: {properties: %w[color], at_rules_with_styles: %w[media]}}
      result = Sanitize::CSS.stylesheet(css, config)

      refute_includes(result, "position")
      refute_includes(result, "url(")
    end

    it "should validate URLs inside simple blocks" do
      _(Sanitize::CSS.properties("color:[url(javascript:alert(1))]", Sanitize::Config::RELAXED))
        .must_equal ""
    end

    it "should allow simple blocks that don't contain bad URLs" do
      css = "grid-template-columns:[full-start] 1fr [full-end]"
      _(Sanitize::CSS.properties(css, Sanitize::Config::RELAXED)).must_equal css
    end
  end

  describe "sanitization bypass via nested rule in property value" do
    # Browsers that support CSS nesting reparse an invalid declaration that
    # contains a `{}` block as a nested style rule, so a `{}` block in an
    # allowlisted property's value could be used to smuggle in disallowed
    # properties.

    before do
      @config = {css: {properties: %w[color]}}
    end

    it "should not allow properties to be smuggled in a nested rule in a stylesheet" do
      css = "p{color:hover{position:fixed;top:0}}"
      result = Sanitize::CSS.stylesheet(css, @config)

      refute_includes(result, "position")
      _(result).must_equal "p{}"
    end

    it "should not allow properties to be smuggled in a nested rule in a <style> element" do
      html = "<style>p{color:hover{position:fixed;top:0}}</style>"
      config = Sanitize::Config.merge(Sanitize::Config::RELAXED, @config)
      result = Sanitize.fragment(html, config)

      refute_includes(result, "position")
    end

    it "should not allow properties to be smuggled after a nested rule in a style attribute" do
      html = "<p style='color:x{a:b} position:fixed'>hi</p>"
      config = Sanitize::Config.merge(Sanitize::Config::RELAXED, @config)
      result = Sanitize.fragment(html, config)

      refute_includes(result, "position")
    end

    it "should not allow {} blocks nested inside other blocks or functions" do
      _(Sanitize::CSS.properties("color:[{position:fixed}]", @config)).must_equal ""
      _(Sanitize::CSS.properties("color:rgb({position:fixed})", @config)).must_equal ""
    end

    it "should not allow a property whose entire value is a {} block" do
      _(Sanitize::CSS.properties("color:{position:fixed}", @config)).must_equal ""
    end
  end

  describe "sanitization bypass via at-rule in a list of declarations" do
    # Browsers that support CSS nesting parse the block of an at-rule like
    # `@media` that appears in a list of declarations (such as the contents of
    # a style rule) as more declarations rather than as rules, so a declaration
    # disguised as a style rule's selector could be used to smuggle in
    # disallowed properties.

    before do
      @config = {css: {properties: %w[color], protocols: [], at_rules_with_styles: %w[container media supports]}}
    end

    it "should not allow properties to be smuggled in a nested @media rule" do
      css = "p{@media all{position:fixed;top:0;background:url(https://example.com/x);a{}}}"
      result = Sanitize::CSS.stylesheet(css, @config)

      refute_includes(result, "position")
      refute_includes(result, "url(")
    end

    it "should not allow properties to be smuggled in a nested @supports rule in a <style> element" do
      html = "<style>p{@supports (color:red){position:fixed;a{}}}</style>"
      config = Sanitize::Config.merge(Sanitize::Config::RELAXED, @config)
      result = Sanitize.fragment(html, config)

      refute_includes(result, "position")
    end

    it "should not allow properties to be smuggled in multiple levels of nested at-rules" do
      css = "p{@media all{@supports (x:y){@container (width>1px){position:fixed;a{}}}}}"
      result = Sanitize::CSS.stylesheet(css, @config)

      refute_includes(result, "position")
    end

    it "should sanitize declarations in nested at-rules" do
      css = "p{color:blue;@media all{color:red;position:fixed}}"
      _(Sanitize::CSS.stylesheet(css, @config)).must_equal "p{color:blue;@media all{color:red;}}"
    end

    it "should not allow properties to be smuggled in an at-rule in properties that may be embedded in a style rule" do
      css = "color:red;@media all{position:fixed;a{}}"
      result = Sanitize::CSS.properties(css, @config)

      refute_includes(result, "position")
    end

    it "should not allow properties to be smuggled in an at-rule nested in an at-rule with properties" do
      config = Sanitize::Config.merge(@config, css: {at_rules_with_properties: %w[font-face page]})

      %w[font-face page].each do |name|
        result = Sanitize::CSS.stylesheet("@#{name}{@media all{position:fixed;a{}}}", config)
        refute_includes(result, "position")
      end
    end

    it "should not allow properties to be smuggled when a list of declarations is passed to tree!" do
      tree = Crass.parse_properties("color:red;@media all{position:fixed;a{}}")
      Sanitize::CSS.tree!(tree, @config)

      refute_includes(Crass::Parser.stringify(tree), "position")
    end

    it "should not allow style rules whose selectors contain semicolons" do
      _(Sanitize::CSS.stylesheet("@media all{x;@import url(x.css);a{color:red}}", @config)).must_equal "@media all{}"
      _(Sanitize::CSS.stylesheet("@media all{a:is(x;y){color:red}}", @config)).must_equal "@media all{}"
    end

    it "should still sanitize the blocks of top-level at-rules as rules" do
      css = "@media all{a{color:red}}"
      _(Sanitize::CSS.stylesheet(css, @config)).must_equal css
    end
  end

  describe "sanitization bypass via Crass maximum nesting depth" do
    # Crass replaces blocks and functions nested more deeply than its maximum
    # nesting depth with `:error` nodes whose contents aren't parsed, but which
    # are preserved verbatim when the tree is stringified.

    before do
      @depth = Crass::Parser::DEFAULT_MAXIMUM_DEPTH
    end

    it "should not allow a nested rule to be smuggled in a property value beyond the maximum depth" do
      css = ("@media all{" * (@depth - 1)) + "p{color:not(z){position:fixed}}" + ("}" * (@depth - 1))
      config = {css: {properties: %w[color], at_rules_with_styles: %w[media]}}
      result = Sanitize::CSS.stylesheet(css, config)

      refute_includes(result, "position")
    end

    it "should not allow a style rule beyond the maximum depth" do
      css = ("@media all{" * @depth) + "p{position:fixed}" + ("}" * @depth)
      config = {css: {properties: %w[color], at_rules_with_styles: %w[media]}}
      result = Sanitize::CSS.stylesheet(css, config)

      refute_includes(result, "position")
    end

    it "should not allow a URL beyond the maximum depth to skip protocol validation" do
      css = "background:" + ("[" * (@depth + 1)) + "url(javascript:alert(1))" + ("]" * (@depth + 1))
      _(Sanitize::CSS.properties(css, Sanitize::Config::RELAXED)).must_equal ""
    end

    it "should not allow a bad URL beyond the maximum depth in a selector" do
      css = "a" + ("(" * (@depth + 1)) + %[url(x"\\\\)] + (")" * (@depth + 1)) + "{color:red}"
      result = Sanitize::CSS.stylesheet(css, Sanitize::Config::RELAXED)

      refute_includes(result, "url(")
    end

    it "should not allow a bad URL beyond the maximum depth in an at-rule prelude" do
      css = "@media " + ("(" * (@depth + 1)) + %[url(x"\\\\)] + (")" * (@depth + 1)) + "{a{color:red}}"
      result = Sanitize::CSS.stylesheet(css, Sanitize::Config::RELAXED)

      refute_includes(result, "url(")
    end

    it "should allow properties nested up to the maximum depth" do
      css = "color:" + ("(" * (@depth - 1)) + "red" + (")" * (@depth - 1))
      config = {css: {properties: %w[color]}}

      _(Sanitize::CSS.properties(css, config)).must_equal css
    end
  end

  describe "sanitization bypass via CSS at-rule in HTML <style> element" do
    before do
      @s = Sanitize.new(Sanitize::Config::RELAXED)
    end

    it "is not possible to prematurely end a <style> element" do
      assert_equal(
        %[<style>@media<\\/style><iframe srcdoc='<script>alert(document.domain)<\\/script>'>{}</style>],
        @s.fragment(%[<style>@media</sty/**/le><iframe srcdoc='<script>alert(document.domain)</script>'></style>])
      )
    end
  end
end
