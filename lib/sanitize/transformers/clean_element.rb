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
        @remove_element_contents.merge(config[:remove_contents].map(&:to_s))
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

      allow_data_attributes = attr_whitelist.include?(:data)

      if attr_whitelist.empty?
        # Delete all attributes from elements with no whitelisted attributes.
        node.attribute_nodes.each {|attr| attr.unlink }
      else
        # Delete any attribute that isn't allowed on this element.
        node.attribute_nodes.each do |attr|
          attr_name = attr.name.downcase

          unless attr_whitelist.include?(attr_name)
            # The attribute isn't explicitly whitelisted.

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
