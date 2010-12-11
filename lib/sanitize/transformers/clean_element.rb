class Sanitize; module Transformers

  class CleanElement
    def initialize(config)
      @config = config

      # For faster lookups.
      @add_attributes          = config[:add_attributes]
      @allowed_elements        = {}
      @attributes              = config[:attributes]
      @protocols               = config[:protocols]
      @remove_all_contents     = false
      @remove_element_contents = {}
      @whitespace_elements     = {}

      config[:elements].each {|el| @allowed_elements[el] = true }
      config[:whitespace_elements].each {|el| @whitespace_elements[el] = true }

      if config[:remove_contents].is_a?(Array)
        config[:remove_contents].each {|el| @remove_element_contents[el] = true }
      else
        @remove_all_contents = !!config[:remove_contents]
      end
    end

    def call(env)
      name = env[:node_name]
      node = env[:node]

      return if env[:is_whitelisted] || !node.element?

      # Delete any element that isn't in the config whitelist.
      unless @allowed_elements[name]
        # Elements like br, div, p, etc. need to be replaced with whitespace in
        # order to preserve readability.
        if @whitespace_elements[name]
          node.add_previous_sibling(' ')
          node.add_next_sibling(' ') unless node.children.empty?
        end

        unless @remove_all_contents || @remove_element_contents[name]
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
