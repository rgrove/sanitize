class Sanitize; module Transformers

  class CleanElement

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
      ' ' => '%20',
      '"' => '%22'
    }

    # Regex that matches any single character that needs to be escaped in
    # attributes affected by unsafe libxml2 behavior.
    UNSAFE_LIBXML_ESCAPE_REGEX = /[ "]/

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

            if del
              attr.unlink
            else
              # Leading and trailing whitespace around URLs is ignored at parse
              # time. Stripping it here prevents it from being escaped by the
              # libxml2 workaround below.
              attr.value = attr.value.strip
            end
          end
        end
      end

      # libxml2 >= 2.9.2 doesn't escape comments within some attributes, in an
      # attempt to preserve server-side includes. This can result in XSS since
      # an unescaped double quote can allow an attacker to inject a
      # non-whitelisted attribute.
      #
      # Sanitize works around this by implementing its own escaping for
      # affected attributes, some of which can exist on any element and some
      # of which can only exist on `<a>` elements.
      #
      # The relevant libxml2 code is here:
      # <https://github.com/GNOME/libxml2/commit/960f0e275616cadc29671a218d7fb9b69eb35588>
      node.attribute_nodes.each do |attr|
        attr_name = attr.name.downcase
        if UNSAFE_LIBXML_ATTRS_GLOBAL.include?(attr_name) ||
          (name == 'a' && UNSAFE_LIBXML_ATTRS_A.include?(attr_name))
            attr.value = attr.value.gsub(UNSAFE_LIBXML_ESCAPE_REGEX, UNSAFE_LIBXML_ESCAPE_CHARS)
        end
      end

      # Add required attributes.
      if @add_attributes.has_key?(name)
        @add_attributes[name].each {|key, val| node[key] = val }
      end
    end
  end

end; end
