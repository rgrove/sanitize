class Sanitize; module Transformers

  class CleanElement
    def initialize(config)
      @config = config

      # For faster lookups.
      @add_attributes          = config[:add_attributes]
      @allowed_elements        = Set.new(config[:elements])
      @attributes              = config[:attributes]
      @protocols               = config[:protocols]
      @remove_all_contents     = false
      @remove_element_contents = Set.new
      @whitespace_elements     = Set.new(config[:whitespace_elements])

      if config[:remove_contents].is_a?(Array)
        @remove_element_contents.merge(config[:remove_contents])
      else
        @remove_all_contents = !!config[:remove_contents]
      end
    end

    def call(env)
      name = env[:node_name]
      node = env[:node]

      return if env[:is_whitelisted] || !node.element?

      # Delete any element that isn't in the config whitelist.
      unless @allowed_elements.include?(name)
        # Elements like br, div, p, etc. need to be replaced with whitespace in
        # order to preserve readability.
        if @whitespace_elements.include?(name)
          node.add_previous_sibling(Nokogiri::XML::Text.new(' ', node.document))

          unless node.children.empty?
            node.add_next_sibling(Nokogiri::XML::Text.new(' ', node.document))
          end
        end

        unless @remove_all_contents || @remove_element_contents.include?(name)
          node.children.each {|n| node.add_previous_sibling(n) }
        end

        node.unlink
        return
      end

      attr_whitelist = Set.new((@attributes[name] || []) +
          (@attributes[:all] || []))

      if attr_whitelist.empty?
        # Delete all attributes from elements with no whitelisted attributes.
        node.attribute_nodes.each {|attr| attr.unlink }
      else
        # Delete any attribute that isn't in the whitelist for this element.
        node.attribute_nodes.each do |attr|
          attr.unlink unless attr_whitelist.include?(attr.name.downcase)
        end

        # Delete remaining attributes that use unacceptable protocols.
        if @protocols.has_key?(name)
          protocol = @protocols[name]

          node.attribute_nodes.each do |attr|
            attr_name = attr.name.downcase
            next false unless protocol.has_key?(attr_name)

            del = if attr.value.to_s.downcase =~ REGEX_PROTOCOL
              !protocol[attr_name].include?($1.downcase)
            else
              !protocol[attr_name].include?(:relative)
            end

            attr.unlink if del
          end
        end
      end

      # Add required attributes.
      if @add_attributes.has_key?(name)
        @add_attributes[name].each {|key, val| node[key] = val }
      end
    end
  end

end; end
