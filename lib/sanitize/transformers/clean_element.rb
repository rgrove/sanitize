# encoding: utf-8

require 'set'

class Sanitize; module Transformers; class CleanElement

  # Matches a valid HTML5 data attribute name. The unicode ranges included here
  # are a conservative subset of the full range of characters that are
  # technically allowed, with the intent of matching the most common characters
  # used in data attribute names while excluding uncommon or potentially
  # misleading characters, or characters with the potential to be normalized
  # into unsafe or confusing forms.
  #
  # If you need data attr names with characters that aren't included here (such
  # as combining marks, full-width characters, or CJK), please consider creating
  # a custom transformer to validate attributes according to your needs.
  #
  # http://www.whatwg.org/specs/web-apps/current-work/multipage/elements.html#embedding-custom-non-visible-data-with-the-data-*-attributes
  REGEX_DATA_ATTR = /\Adata-(?!xml)[a-z_][\w.\u00E0-\u00F6\u00F8-\u017F\u01DD-\u02AF-]*\z/u

  def initialize(config)
    @add_attributes          = config[:add_attributes]
    @attributes              = config[:attributes].dup
    @elements                = config[:elements]
    @protocols               = config[:protocols]
    @remove_all_contents     = false
    @remove_element_contents = Set.new
    @whitespace_elements     = {}

    @attributes.each do |element_name, attrs|
      unless element_name == :all
        @attributes[element_name] = Set.new(attrs).merge(@attributes[:all] || [])
      end
    end

    # Backcompat: if :whitespace_elements is a Set, convert it to a hash.
    if config[:whitespace_elements].is_a?(Set)
      config[:whitespace_elements].each do |element|
        @whitespace_elements[element] = {:before => ' ', :after => ' '}
      end
    else
      @whitespace_elements = config[:whitespace_elements]
    end

    if config[:remove_contents].is_a?(Set)
      @remove_element_contents.merge(config[:remove_contents].map(&:to_s))
    else
      @remove_all_contents = !!config[:remove_contents]
    end
  end

  def call(env)
    node = env[:node]
    return if node.type != Nokogiri::XML::Node::ELEMENT_NODE || env[:is_whitelisted]

    name = env[:node_name]

    # Delete any element that isn't in the config whitelist, unless the node has
    # already been deleted from the document.
    #
    # It's important that we not try to reparent the children of a node that has
    # already been deleted, since that seems to trigger a memory leak in
    # Nokogiri.
    unless @elements.include?(name) || node.parent.nil?
      # Elements like br, div, p, etc. need to be replaced with whitespace in
      # order to preserve readability.
      if @whitespace_elements.include?(name)
        node.add_previous_sibling(Nokogiri::XML::Text.new(@whitespace_elements[name][:before].to_s, node.document))

        unless node.children.empty?
          node.add_next_sibling(Nokogiri::XML::Text.new(@whitespace_elements[name][:after].to_s, node.document))
        end
      end

      unless @remove_all_contents || @remove_element_contents.include?(name)
        node.add_previous_sibling(node.children)
      end

      node.unlink
      return
    end

    attr_whitelist = @attributes[name] || @attributes[:all]

    if attr_whitelist.nil?
      # Delete all attributes from elements with no whitelisted attributes.
      node.attribute_nodes.each {|attr| attr.unlink }
    else
      allow_data_attributes = attr_whitelist.include?(:data)

      # Delete any attribute that isn't allowed on this element.
      node.attribute_nodes.each do |attr|
        attr_name = attr.name.downcase

        if attr_whitelist.include?(attr_name)
          # The attribute is whitelisted.

          # Remove any attributes that use unacceptable protocols.
          if @protocols.include?(name) && @protocols[name].include?(attr_name)
            attr_protocols = @protocols[name][attr_name]

            if attr.value.to_s.downcase =~ REGEX_PROTOCOL
              attr.unlink unless attr_protocols.include?($1.downcase)
            else
              attr.unlink unless attr_protocols.include?(:relative)
            end
          end
        else
          # The attribute isn't whitelisted.

          if allow_data_attributes && attr_name.start_with?('data-')
            # Arbitrary data attributes are allowed. Verify that the attribute
            # is a valid data attribute.
            attr.unlink unless attr_name =~ REGEX_DATA_ATTR
          else
            # Either the attribute isn't a data attribute, or arbitrary data
            # attributes aren't allowed. Remove the attribute.
            attr.unlink
          end
        end
      end
    end

    # Add required attributes.
    if @add_attributes.include?(name)
      @add_attributes[name].each {|key, val| node[key] = val }
    end
  end

end; end; end
