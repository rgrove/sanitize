# frozen_string_literal: true

class Sanitize
  module Transformers
    class CleanElement
      # Maps the namespace URI of each foreign element type supported by HTML to
      # the name of its root element.
      FOREIGN_NAMESPACE_ROOTS = {
        "http://www.w3.org/1998/Math/MathML" => "math",
        "http://www.w3.org/2000/svg" => "svg"
      }.freeze

      # Matches a valid HTML5 data attribute name. The unicode ranges included
      # here are a conservative subset of the full range of characters that are
      # technically allowed, with the intent of matching the most common
      # characters used in data attribute names while excluding uncommon or
      # potentially misleading characters, or characters with the potential to
      # be normalized into unsafe or confusing forms.
      #
      # If you need data attr names with characters that aren't included here
      # (such as combining marks, full-width characters, or CJK), please
      # consider creating a custom transformer to validate attributes according
      # to your needs.
      #
      # https://html.spec.whatwg.org/multipage/dom.html#embedding-custom-non-visible-data-with-the-data-*-attributes
      REGEX_DATA_ATTR = /\Adata-(?!xml)[a-z_][\w.\u00E0-\u00F6\u00F8-\u017F\u01DD-\u02AF-]*\z/u

      # Maps `<select>` and related elements to the names of the elements that
      # browsers using legacy `<select>` parsing rules allow as their children.
      SELECT_CONTENT_MODEL = {
        "optgroup" => Set["option"].freeze,
        "option" => Set.new.freeze,
        "select" => Set["hr", "optgroup", "option"].freeze
      }.freeze

      # Elements whose content is treated as unescaped text by HTML parsers.
      UNESCAPED_TEXT_ELEMENTS = Set.new(%w[
        iframe
        noembed
        noframes
        noscript
        plaintext
        script
        style
        xmp
      ])

      # Attributes that need additional escaping on `<a>` elements due to unsafe
      # libxml2 behavior.
      UNSAFE_LIBXML_ATTRS_A = Set.new(%w[
        name
      ])

      # Attributes that need additional escaping on all elements due to unsafe
      # libxml2 behavior.
      UNSAFE_LIBXML_ATTRS_GLOBAL = Set.new(%w[
        action
        href
        src
      ])

      # Mapping of original characters to escape sequences for characters that
      # should be escaped in attributes affected by unsafe libxml2 behavior.
      UNSAFE_LIBXML_ESCAPE_CHARS = {
        " " => "%20",
        '"' => "%22"
      }

      # Regex that matches any single character that needs to be escaped in
      # attributes affected by unsafe libxml2 behavior.
      UNSAFE_LIBXML_ESCAPE_REGEX = /[ "]/

      def initialize(config)
        @add_attributes = config[:add_attributes]
        @attributes = config[:attributes].dup
        @elements = config[:elements]
        @protocols = config[:protocols]
        @remove_all_contents = false
        @remove_element_contents = Set.new
        @whitespace_elements = {}

        @attributes.each do |element_name, attrs|
          unless element_name == :all
            @attributes[element_name] = Set.new(attrs).merge(@attributes[:all] || [])
          end
        end

        # Backcompat: if :whitespace_elements is a Set, convert it to a hash.
        if config[:whitespace_elements].is_a?(Set)
          config[:whitespace_elements].each do |element|
            @whitespace_elements[element] = {before: " ", after: " "}
          end
        else
          @whitespace_elements = config[:whitespace_elements]
        end

        if config[:remove_contents].is_a?(Enumerable)
          @remove_element_contents.merge(config[:remove_contents].map(&:to_s))
        else
          @remove_all_contents = !!config[:remove_contents]
        end
      end

      def call(env)
        node = env[:node]
        return if node.type != Nokogiri::XML::Node::ELEMENT_NODE

        name = env[:node_name]
        parent = node.parent

        # Some elements are always removed, even if they're allowlisted, since
        # browsers would parse them differently than Nokogiri did.
        force_remove = orphaned_foreign_element?(node, name, parent) ||
          invalid_select_descendant?(name, parent) ||
          text_content_element?(parent)

        return if env[:is_allowlisted] && !force_remove

        # Delete any element that isn't in the config allowlist, unless the node
        # has already been deleted from the document.
        #
        # It's important that we not try to reparent the children of a node that
        # has already been deleted, since that seems to trigger a memory leak in
        # Nokogiri.
        if (force_remove || !@elements.include?(name)) && !parent.nil?
          # Elements like br, div, p, etc. need to be replaced with whitespace
          # in order to preserve readability.
          if @whitespace_elements.include?(name)
            node.add_previous_sibling(Nokogiri::XML::Text.new(@whitespace_elements[name][:before].to_s, node.document))

            unless node.children.empty?
              node.add_next_sibling(Nokogiri::XML::Text.new(@whitespace_elements[name][:after].to_s, node.document))
            end
          end

          unless node.children.empty?
            unless @remove_all_contents || @remove_element_contents.include?(name)
              node.add_previous_sibling(node.children)
            end
          end

          node.unlink
          return
        end

        attr_allowlist = @attributes[name] || @attributes[:all]

        if attr_allowlist.nil?
          # Delete all attributes from elements with no allowlisted attributes.
          node.attribute_nodes.each { |attr| attr.unlink }
        else
          allow_data_attributes = attr_allowlist.include?(:data)

          # Delete any attribute that isn't allowed on this element.
          node.attribute_nodes.each do |attr|
            attr_name = attr.name.downcase

            unless attr_allowlist.include?(attr_name)
              # The attribute isn't in the allowlist, but may still be allowed
              # if it's a data attribute.

              unless allow_data_attributes && attr_name.start_with?("data-") && attr_name =~ REGEX_DATA_ATTR
                # Either the attribute isn't a data attribute or arbitrary data
                # attributes aren't allowed. Remove the attribute.
                attr.unlink
                next
              end
            end

            # The attribute is allowed.

            # Remove any attributes that use unacceptable protocols.
            if @protocols.include?(name) && @protocols[name].include?(attr_name)
              attr_protocols = @protocols[name][attr_name]

              if attr.value =~ REGEX_PROTOCOL
                unless attr_protocols.include?($1.downcase)
                  attr.unlink
                  next
                end

              else
                unless attr_protocols.include?(:relative)
                  attr.unlink
                  next
                end
              end

              # Leading and trailing whitespace around URLs is ignored at parse
              # time. Stripping it here prevents it from being escaped by the
              # libxml2 workaround below.
              attr.value = attr.value.strip
            end

            # libxml2 >= 2.9.2 doesn't escape comments within some attributes,
            # in an attempt to preserve server-side includes. This can result in
            # XSS since an unescaped double quote can allow an attacker to
            # inject a non-allowlisted attribute.
            #
            # Sanitize works around this by implementing its own escaping for
            # affected attributes, some of which can exist on any element and
            # some of which can only exist on `<a>` elements.
            #
            # This fix is technically no longer necessary with Nokogumbo >= 2.0
            # since it no longer uses libxml2's serializer, but it's retained to
            # avoid breaking use cases where people might be sanitizing
            # individual Nokogiri nodes and then serializing them manually
            # without Nokogumbo.
            #
            # The relevant libxml2 code is here:
            # <https://github.com/GNOME/libxml2/commit/960f0e275616cadc29671a218d7fb9b69eb35588>
            if UNSAFE_LIBXML_ATTRS_GLOBAL.include?(attr_name) ||
                (name == "a" && UNSAFE_LIBXML_ATTRS_A.include?(attr_name))

              attr.value = attr.value.gsub(UNSAFE_LIBXML_ESCAPE_REGEX, UNSAFE_LIBXML_ESCAPE_CHARS)
            end
          end
        end

        # Add required attributes.
        if @add_attributes.include?(name)
          @add_attributes[name].each { |key, val| node[key] = val }
        end

        # Element-specific special cases.
        case name

        # If this is an allowlisted iframe that has children, remove all its
        # children. The HTML standard says iframes shouldn't have content, but
        # when they do, this content is parsed as text and is serialized
        # verbatim without being escaped, which is unsafe because legacy
        # browsers may still render it and execute `<script>` content. So the
        # safe and correct thing to do is to always remove iframe content.
        when "iframe"
          if !node.children.empty?
            node.children.each do |child|
              child.unlink
            end
          end

        # Prevent the use of `<meta>` elements that set a charset other than
        # UTF-8, since Sanitize's output is always UTF-8.
        when "meta"
          if node.has_attribute?("charset") &&
              node["charset"].downcase != "utf-8"

            node["charset"] = "utf-8"
          end

          if node.has_attribute?("http-equiv") &&
              node.has_attribute?("content") &&
              node["http-equiv"].downcase == "content-type" &&
              node["content"].downcase =~ /;\s*charset\s*=\s*(?!utf-8)/

            node["content"] = node["content"].gsub(/;\s*charset\s*=.+\z/, ";charset=utf-8")
          end

        # A `<noscript>` element's content is parsed differently in browsers
        # depending on whether or not scripting is enabled. Since Nokogiri
        # doesn't support scripting, it always parses `<noscript>` elements as
        # if scripting is disabled. This results in edge cases where it's not
        # possible to reliably sanitize the contents of a `<noscript>` element
        # because Nokogiri can't fully replicate the parsing behavior of a
        # scripting-enabled browser. The safest thing to do is to simply remove
        # all `<noscript>` elements.
        when "noscript"
          node.unlink
        end
      end

      private

      # Returns `true` if _parent_ is an HTML `<select>`, `<option>`, or
      # `<optgroup>` element and _name_ isn't an element that browsers allow
      # inside it.
      #
      # Browsers that use legacy `<select>` parsing rules ignore the start tags
      # of most elements inside a `<select>` element, including raw text
      # elements like `<style>` and `<xmp>`, so these elements' contents would
      # be parsed as markup. Nokogiri parses these elements the same way, but
      # they can still end up inside a `<select>` element via a `<template>`
      # element or foreign content that Sanitize removes. Since traversal is
      # top-down, removing these elements ensures that only allowed elements
      # and text remain inside `<select>` elements.
      def invalid_select_descendant?(name, parent)
        return false unless parent&.element? && SELECT_CONTENT_MODEL.key?(parent.name.downcase)
        return false if FOREIGN_NAMESPACE_ROOTS.key?(parent.namespace&.href)

        !SELECT_CONTENT_MODEL[parent.name.downcase].include?(name)
      end

      # Returns `true` if _node_ is a MathML or SVG element other than a
      # `<math>` or `<svg>` element and its parent isn't a MathML or SVG element.
      #
      # This happens when Sanitize removes a `<math>` or `<svg>` element but
      # keeps its contents. Nokogiri parsed these descendants as foreign
      # elements, but browsers would reparse them as HTML elements, which may
      # be parsed very differently. For example, the contents of a foreign
      # `<textarea>` element are parsed as markup rather than as text. Since
      # traversal is top-down, removing these elements ensures that no foreign
      # element is kept without a foreign root.
      def orphaned_foreign_element?(node, name, parent)
        root_name = FOREIGN_NAMESPACE_ROOTS[node.namespace&.href]
        return false if root_name.nil? || name == root_name

        !(parent&.element? && FOREIGN_NAMESPACE_ROOTS.key?(parent.namespace&.href))
      end

      # Returns `true` if _parent_ is a text content element, such as
      # `<textarea>` or `<xmp>`.
      #
      # Browsers parse the contents of these elements as text when they're in
      # the HTML namespace, so any element inside one must have been parsed in
      # a foreign namespace. Since traversal is top-down, removing these
      # elements ensures that only text remains inside text content elements.
      def text_content_element?(parent)
        !!parent&.element? && TEXT_CONTENT_ELEMENTS.include?(parent.name.downcase)
      end
    end
  end
end
