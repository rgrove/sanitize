# frozen_string_literal: true

require "crass"
require "set"

class Sanitize
  class CSS
    attr_reader :config

    # -- Class Methods ---------------------------------------------------------

    # Sanitizes inline CSS style properties.
    #
    # This is most useful for sanitizing non-stylesheet fragments of CSS like
    # you would find in the `style` attribute of an HTML element. To sanitize a
    # full CSS stylesheet, use {.stylesheet}.
    #
    # @example
    #   Sanitize::CSS.properties("background: url(foo.png); color: #fff;")
    #
    # @return [String] Sanitized CSS properties.
    def self.properties(css, config = {})
      new(config).properties(css)
    end

    # Sanitizes a full CSS stylesheet.
    #
    # A stylesheet may include selectors, at-rules, and comments. To sanitize
    # only inline style properties such as the contents of an HTML `style`
    # attribute, use {.properties}.
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
    #   Sanitize::CSS.stylesheet(css, Sanitize::Config::RELAXED)
    #
    # @return [String] Sanitized CSS stylesheet.
    def self.stylesheet(css, config = {})
      new(config).stylesheet(css)
    end

    # Sanitizes the given Crass CSS parse tree and all its children, modifying
    # it in place.
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
    #   tree = Crass.parse(css)
    #   Sanitize::CSS.tree!(tree, Sanitize::Config::RELAXED)
    #
    # @return [Array] Sanitized Crass CSS parse tree.
    def self.tree!(tree, config = {})
      new(config).tree!(tree)
    end

    # -- Instance Methods ------------------------------------------------------

    # Returns a new Sanitize::CSS object initialized with the settings in
    # _config_.
    def initialize(config = {})
      @config = Config.merge(Config::DEFAULT[:css], config[:css] || config)

      @at_rules = Set.new(@config[:at_rules])
      @at_rules_with_properties = Set.new(@config[:at_rules_with_properties])
      @at_rules_with_styles = Set.new(@config[:at_rules_with_styles])
      @import_url_validator = @config[:import_url_validator]
    end

    # Sanitizes inline CSS style properties.
    #
    # This is most useful for sanitizing non-stylesheet fragments of CSS like
    # you would find in the `style` attribute of an HTML element. To sanitize a
    # full CSS stylesheet, use {#stylesheet}.
    #
    # @example
    #   scss = Sanitize::CSS.new(Sanitize::Config::RELAXED)
    #   scss.properties("background: url(foo.png); color: #fff;")
    #
    # @return [String] Sanitized CSS properties.
    def properties(css)
      tree = Crass.parse_properties(css,
        preserve_comments: @config[:allow_comments],
        preserve_hacks: @config[:allow_hacks])

      tree!(tree)
      Crass::Parser.stringify(tree)
    end

    # Sanitizes a full CSS stylesheet.
    #
    # A stylesheet may include selectors, at-rules, and comments. To sanitize
    # only inline style properties such as the contents of an HTML `style`
    # attribute, use {#properties}.
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
        preserve_comments: @config[:allow_comments],
        preserve_hacks: @config[:allow_hacks])

      tree!(tree)
      Crass::Parser.stringify(tree)
    end

    # Sanitizes the given Crass CSS parse tree and all its children, modifying
    # it in place.
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
    #   tree = Crass.parse(css)
    #
    #   scss.tree!(tree)
    #
    # @return [Array] Sanitized Crass CSS parse tree.
    def tree!(tree)
      sanitize_tree!(tree, nested: false)
    end

    # -- Protected Instance Methods --------------------------------------------
    protected

    # Sanitizes a CSS at-rule node. Returns the sanitized node, or `nil` if the
    # current config doesn't allow this at-rule.
    #
    # If _nested_ is `true`, the at-rule is nested inside a style rule.
    def at_rule!(rule, nested:)
      name = rule[:name].downcase

      return nil if contains_invalid_node?(rule[:prelude])

      if @at_rules_with_styles.include?(name)
        # Browsers that support CSS nesting parse the block of an at-rule like
        # `@media` that's nested inside a style rule as declarations rather than
        # rules, so it must be sanitized as declarations. Otherwise a
        # declaration like `position:fixed;a{}` would be parsed as a style rule
        # with the selector `position:fixed;a` and would bypass the property
        # allowlist.
        parse_method = nested ? :parse_properties : :parse_rules

        styles = Crass::Parser.public_send(parse_method, rule[:block],
          preserve_comments: @config[:allow_comments],
          preserve_hacks: @config[:allow_hacks])

        rule[:block] = sanitize_tree!(styles, nested: nested)

      elsif @at_rules_with_properties.include?(name)
        props = Crass::Parser.parse_properties(rule[:block],
          preserve_comments: @config[:allow_comments],
          preserve_hacks: @config[:allow_hacks])

        rule[:block] = sanitize_tree!(props, nested: nested)

      elsif @at_rules.include?(name)
        return nil if name == "import" && !import_url_allowed?(rule)
        return nil if rule.has_key?(:block)
      else
        return nil
      end

      rule
    end

    # Returns `true` if the given array of Crass nodes contains an invalid node
    # (see {#invalid_node?}) at any depth.
    def contains_invalid_node?(nodes)
      contains_node?(nodes) { |node| invalid_node?(node) }
    end

    # Returns `true` if the given array of Crass nodes contains a node at any
    # depth for which the given block returns a truthy value.
    def contains_node?(nodes)
      return false unless Array === nodes

      stack = nodes.dup

      until stack.empty?
        node = stack.pop
        next unless Hash === node
        return true if yield(node)

        value = node[:value]
        stack.concat(value) if Array === value
      end

      false
    end

    # Returns `true` if the given CSS function name is an image-related function
    # that may contain image URLs that need to be validated.
    def image_function?(name)
      ["image", "image-set", "-webkit-image-set"].include?(name)
    end

    # Passes the URL value of an @import rule to a block to ensure
    # it's an allowed URL
    def import_url_allowed?(rule)
      return true unless @import_url_validator

      url_token = rule[:tokens].detect { |t| t[:node] == :url || t[:node] == :string }

      # don't allow @imports with no URL value
      return false unless url_token && (import_url = url_token[:value])

      @import_url_validator.call(import_url)
    end

    # Returns `true` if the given Crass node is a `:bad_url` or `:error` node.
    #
    # A bad URL is invalid CSS that a browser will discard, but a parser that
    # disagrees with the browser about where a bad URL ends could be tricked
    # into hiding CSS inside it.
    #
    # An `:error` node is CSS that Crass couldn't or wouldn't parse, such as a
    # block nested more deeply than Crass's maximum nesting depth. Its contents
    # are never inspected, but they're preserved verbatim when the tree is
    # stringified, so a browser would still see them.
    #
    # It's safest to reject any construct that contains either one.
    def invalid_node?(node)
      node[:node] == :bad_url || node[:node] == :error
    end

    # Sanitizes a CSS property node. Returns the sanitized node, or `nil` if the
    # current config doesn't allow this property.
    def property!(prop)
      name = prop[:name].downcase

      # Preserve IE * and _ hacks if desired.
      if @config[:allow_hacks]
        name.slice!(0) if /\A[*_]/.match?(name)
      end

      return nil unless @config[:properties].include?(name)

      # Reject properties that contain an invalid node (see {#invalid_node?}) or
      # a `{}` block at any depth.
      #
      # A `{}` block isn't valid in a standard property value, and browsers
      # that support CSS nesting will reparse an invalid declaration that
      # contains one as a nested style rule (e.g. `color:hover{position:fixed}`
      # becomes the rule `color:hover { position: fixed }`), which would allow
      # disallowed properties to be smuggled past the sanitizer.
      return nil if contains_node?(prop[:children]) { |node|
        invalid_node?(node) || (node[:node] == :simple_block && node[:start] == "{")
      }

      nodes = prop[:children].dup
      combined_value = +""

      nodes.each do |child|
        value = child[:value]

        case child[:node]
        when :ident
          combined_value << value.downcase if String === value

        when :function
          if child.key?(:name)
            name = child[:name].downcase

            if name == "url"
              return nil unless valid_url?(child)
            end

            if image_function?(name)
              return nil unless valid_image?(child)
            end

            combined_value << name
            return nil if name == "expression" || combined_value == "expression"
          end

          if Array === value
            nodes.concat(value)
          elsif String === value
            lowercase_value = value.downcase
            combined_value << lowercase_value
            return nil if lowercase_value == "expression" || combined_value == "expression"
          end

        when :url
          return nil unless valid_url?(child)

        when :simple_block
          nodes.concat(value) if Array === value
        end
      end

      prop
    end

    # Sanitizes the given Crass CSS parse tree and all its children, modifying
    # it in place. See {#tree!}.
    #
    # If _nested_ is `true`, the tree is the contents of a style rule, or of an
    # at-rule nested inside a style rule.
    def sanitize_tree!(tree, nested:)
      preceded_by_property = false

      tree.map! do |node|
        next nil if node.nil?

        case node[:node]
        when :at_rule
          preceded_by_property = false
          next at_rule!(node, nested: nested)

        when :comment
          next node if @config[:allow_comments]

        when :property
          prop = property!(node)
          preceded_by_property = !prop.nil?
          next prop

        when :semicolon
          # Only preserve the semicolon if it was preceded by an allowlisted
          # property. Otherwise, omit it in order to prevent redundant
          # semicolons.
          if preceded_by_property
            preceded_by_property = false
            next node
          end

        when :style_rule
          preceded_by_property = false
          next nil if contains_invalid_node?(node.dig(:selector, :tokens))

          sanitize_tree!(node[:children], nested: true)
          next node

        when :whitespace
          next node
        end

        nil
      end

      tree
    end

    # Returns `true` if the given node (which may be of type `:url` or
    # `:function`, since the CSS syntax can produce both) uses an allowlisted
    # protocol.
    def valid_url?(node)
      type = node[:node]

      if type == :function
        return false unless node.key?(:name) && node[:name].downcase == "url"
        return false unless Array === node[:value]

        # A URL function's `:value` should be an array containing no more than
        # one `:string` node and any number of `:whitespace` nodes.
        #
        # If it contains more than one `:string` node, or if it contains any
        # other nodes except `:whitespace` nodes, it's not valid.
        url_string_node = nil

        node[:value].each do |token|
          return false unless Hash === token

          case token[:node]
          when :string
            return false unless url_string_node.nil?
            url_string_node = token

          when :whitespace
            next

          else
            return false
          end
        end

        return false if url_string_node.nil?
        url = url_string_node[:value]
      elsif type == :url
        url = node[:value]
      else
        return false
      end

      if url =~ Sanitize::REGEX_PROTOCOL
        @config[:protocols].include?($1.downcase)
      else
        @config[:protocols].include?(:relative)
      end
    end

    # Returns `true` if the given node is an image-related function and contains
    # only strings that use an allowlisted protocol.
    def valid_image?(node)
      return false unless node[:node] == :function
      return false unless node.key?(:name) && image_function?(node[:name].downcase)
      return false unless Array === node[:value]

      node[:value].each do |token|
        return false unless Hash === token

        case token[:node]
        when :string
          if token[:value] =~ Sanitize::REGEX_PROTOCOL
            return false unless @config[:protocols].include?($1.downcase)
          else
            return false unless @config[:protocols].include?(:relative)
          end
        else
          next
        end
      end
    end
  end
end
