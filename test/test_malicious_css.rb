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
