# frozen_string_literal: true

require "set"

class Sanitize
  module Transformers
    # Names of elements whose content is parsed as text rather than markup when
    # they're in the HTML namespace.
    #
    # An element with one of these names can contain markup if it's in a foreign
    # namespace like MathML or SVG. If Sanitize removes the foreign ancestor but
    # keeps the element, its serialized contents will be reparsed as text inside
    # an HTML element, so a closing tag inside a comment or an unescaped raw
    # text element could break out of the element and inject arbitrary markup.
    # To prevent this, Sanitize removes all elements and comments inside these
    # elements, leaving only text.
    TEXT_CONTENT_ELEMENTS = Set.new(%w[
      iframe
      noembed
      noframes
      noscript
      plaintext
      script
      style
      textarea
      title
      xmp
    ]).freeze

    CleanComment = lambda do |env|
      node = env[:node]

      return unless node.type == Nokogiri::XML::Node::COMMENT_NODE

      # Comments inside text content elements are always removed, even if
      # they're allowlisted, since they can never be serialized safely.
      parent = node.parent

      while parent&.element?
        if TEXT_CONTENT_ELEMENTS.include?(parent.name.downcase)
          node.unlink
          return
        end

        parent = parent.parent
      end

      node.unlink unless env[:config][:allow_comments] || env[:is_allowlisted]
    end
  end
end
