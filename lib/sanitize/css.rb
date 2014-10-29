# encoding: utf-8

require 'crass'
require 'set'

class Sanitize; class CSS
  attr_reader :config

  # Names of CSS at-rules whose blocks may contain properties.
  AT_RULES_WITH_PROPERTIES = Set.new(%w[font-face page])

  # Names of CSS at-rules whose blocks may contain style rules.
  AT_RULES_WITH_STYLES = Set.new(%w[document media supports])

  # -- Class Methods -----------------------------------------------------------

  # Sanitizes inline CSS style properties.
  #
  # This is most useful for sanitizing non-stylesheet fragments of CSS like you
  # would find in the `style` attribute of an HTML element. To sanitize a full
  # CSS stylesheet, use {.stylesheet}.
  #
  # @example
  #   Sanitize::CSS.properties("background: url(foo.png); color: #fff;")
  #
  # @return [String] Sanitized CSS properties.
  def self.properties(css, config = {})
    self.new(config).properties(css)
  end

  def self.stylesheet(css, config = {})
    self.new(config).stylesheet(css)
  end

  def self.tree!(tree, config = {})
    self.new(config).tree!(tree)
  end

  # -- Instance Methods --------------------------------------------------------

  # Returns a new Sanitize::CSS object initialized with the settings in
  # _config_.
  def initialize(config = {})
    @config = Config.merge(Config::DEFAULT[:css], config[:css] || config)
  end

  # Sanitizes inline CSS style properties.
  #
  # This is most useful for sanitizing non-stylesheet fragments of CSS like you
  # would find in the `style` attribute of an HTML element. To sanitize a full
  # CSS stylesheet, use {#stylesheet}.
  #
  # @example
  #   scss = Sanitize::CSS.new(Sanitize::Config::RELAXED)
  #   scss.properties("background: url(foo.png); color: #fff;")
  #
  # @return [String] Sanitized CSS properties.
  def properties(css)
    tree = Crass.parse_properties(css,
      :preserve_comments => @config[:allow_comments],
      :preserve_hacks    => @config[:allow_hacks])

    tree!(tree)
    Crass::Parser.stringify(tree)
  end

  # Sanitizes a full CSS stylesheet.
  #
  # A stylesheet may include selectors, @ rules, and comments. To sanitize only
  # inline style properties such as the contents of an HTML `style` attribute,
  # use {#properties}.
  #
  # @example
  #   css = %[
  #     .foo {
  #       background: url(foo.png);
  #       color: #fff;
  #     }
  #
  #     #bar {
  #       font: 42pt 'Comic Sans MS';
  #     }
  #   ]
  #
  #   scss = Sanitize::CSS.new(Sanitize::Config::RELAXED)
  #   scss.stylesheet(css)
  #
  # @return [String] Sanitized CSS stylesheet.
  def stylesheet(css)
    tree = Crass.parse(css,
      :preserve_comments => @config[:allow_comments],
      :preserve_hacks    => @config[:allow_hacks])

    tree!(tree)
    Crass::Parser.stringify(tree)
  end

  # Sanitizes the given Crass CSS parse tree and all its children, modifying it
  # in place.
  #
  # @example
  #   scss = Sanitize::CSS.new(Sanitize::Config::RELAXED)
  #   tree = Crass.parse(css)
  #
  #   scss.tree!(tree)
  #
  # @return [Array] Sanitized Crass CSS parse tree.
  def tree!(tree)
    tree.map! do |node|
      next nil if node.nil?

      case node[:node]
      when :at_rule
        next at_rule!(node)

      when :comment
        next node if @config[:allow_comments]

      when :property
        next property!(node)

      when :style_rule
        tree!(node[:children])
        next node

      when :whitespace
        next node
      end

      nil
    end

    tree
  end

  # -- Protected Instance Methods ----------------------------------------------
  protected

  # Sanitizes a CSS at-rule node. Returns the sanitized node, or `nil` if the
  # current config doesn't allow this at-rule.
  def at_rule!(rule)
    name = rule[:name].downcase
    return nil unless @config[:at_rules].include?(name)

    if AT_RULES_WITH_STYLES.include?(name)
      # Remove the { and } tokens surrounding the @media block.
      tokens = rule[:block][:tokens][1...-1]

      styles = Crass::Parser.parse_rules(tokens,
        :preserve_comments => @config[:allow_comments],
        :preserve_hacks    => @config[:allow_hacks])

      rule[:block][:value] = tree!(styles)

    elsif AT_RULES_WITH_PROPERTIES.include?(name)
      props = Crass::Parser.parse_properties(rule[:block][:value],
        :preserve_comments => @config[:allow_comments],
        :preserve_hacks    => @config[:allow_hacks])

      rule[:block][:value] = tree!(props)

    else
      rule.delete(:block)
    end

    rule
  end

  # Sanitizes a CSS property node. Returns the sanitized node, or `nil` if the
  # current config doesn't allow this property.
  def property!(prop)
    name = prop[:name].downcase

    # Preserve IE * and _ hacks if desired.
    if @config[:allow_hacks]
      name.slice!(0) if name =~ /\A[*_]/
    end

    return nil unless @config[:properties].include?(name)

    nodes          = prop[:children].dup
    combined_value = ''

    nodes.each do |child|
      value = child[:value]

      case child[:node]
      when :ident
        combined_value << value if String === value

      when :function
        if child.key?(:name)
          return nil if child[:name].downcase == 'expression'
        end

        if Array === value
          nodes.concat(value)
        elsif String === value
          combined_value << value

          if value.downcase == 'expression' || combined_value.downcase == 'expression'
            return nil
          end
        end

      when :url
        if value =~ Sanitize::REGEX_PROTOCOL
          return nil unless @config[:protocols].include?($1.downcase)
        else
          return nil unless @config[:protocols].include?(:relative)
        end

      when :bad_url
        return nil
      end
    end

    prop
  end

end; end
