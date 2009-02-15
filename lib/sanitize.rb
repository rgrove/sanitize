#--
# Copyright (c) 2009 Ryan Grove <ryan@wonko.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#++

# Append this file's directory to the include path if it's not there already.
$:.unshift(File.dirname(File.expand_path(__FILE__)))
$:.uniq!

require 'rubygems'

gem 'hpricot', '~> 0.6'

require 'hpricot'
require 'sanitize/config'
require 'sanitize/config/restricted'
require 'sanitize/config/basic'
require 'sanitize/config/relaxed'

class Sanitize

  # Characters that should be replaced with entities in text nodes.
  ENTITY_MAP = {
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
    "'" => '&#39;'
  }

  # Matches an unencoded ampersand that is not part of a valid character entity
  # reference.
  REGEX_AMPERSAND = /&(?!(?:[a-z]+|#[0-9]+|#x[0-9a-f]+);)/i

  # Matches an attribute value that could be treated by a browser as a URL
  # with a protocol prefix, such as "http:" or "javascript:". Any string of zero
  # or more characters followed by a colon is considered a match, even if the
  # colon is encoded as an entity and even if it's an incomplete entity (which
  # IE6 and Opera will still parse).
  REGEX_PROTOCOL = /^([^:]*)(?:\:|&#0*58|&#x0*3a)/i

  #--
  # Instance Methods
  #++

  # Returns a new Sanitize object initialized with the settings in _config_.
  def initialize(config = {})
    @config = Config::DEFAULT.merge(config)
  end

  # Returns a sanitized copy of _html_.
  def clean(html)
    dupe = html.dup
    clean!(dupe) || dupe
  end

  # Performs clean in place, returning _html_, or +nil+ if no changes were
  # made.
  def clean!(html)
    fragment = Hpricot(html)

    fragment.search('*') do |node|
      if node.bogusetag? || node.doctype? || node.procins? || node.xmldecl?
        node.parent.replace_child(node, '')
        next
      end

      if node.comment?
        node.parent.replace_child(node, '') unless @config[:allow_comments]
      elsif node.elem?
        name = node.name.to_s.downcase

        # Delete any element that isn't in the whitelist.
        unless @config[:elements].include?(name)
          node.parent.replace_child(node, node.children || '')
          next
        end

        node.raw_attributes ||= {}

        attr_whitelist = ((@config[:attributes][name] || []) +
            (@config[:attributes][:all] || [])).uniq

        if attr_whitelist.empty?
          # Delete all attributes from elements with no whitelisted
          # attributes.
          node.raw_attributes = {}
        else
          # Delete any attribute that isn't in the whitelist for this element.
          node.raw_attributes.delete_if do |key, value|
            !attr_whitelist.include?(key.to_s.downcase)
          end

          # Delete remaining attributes that use unacceptable protocols.
          if @config[:protocols].has_key?(name)
            protocol = @config[:protocols][name]

            node.raw_attributes.delete_if do |key, value|
              next false unless protocol.has_key?(key)
              next true if value.nil?

              if value.to_s.downcase =~ REGEX_PROTOCOL
                !protocol[key].include?($1.downcase)
              else
                !protocol[key].include?(:relative)
              end
            end
          end
        end

        # Add required attributes.
        if @config[:add_attributes].has_key?(name)
          node.raw_attributes.merge!(@config[:add_attributes][name])
        end

        # Escape special chars in attribute values.
        node.raw_attributes.each do |key, value|
          node.raw_attributes[key] = Sanitize.encode_html(value)
        end
      end
    end

    # Make one last pass through the fragment and encode all special HTML chars
    # as entities. This eliminates certain types of maliciously-malformed nested
    # tags.
    fragment.search('*') do |node|
      node.swap(Sanitize.encode_html(node.to_original_html)) if node.text?
    end

    result = fragment.to_s
    return result == html ? nil : html[0, html.length] = result
  end

  #--
  # Class Methods
  #++

  class << self
    # Returns a sanitized copy of _html_, using the settings in _config_ if
    # specified.
    def clean(html, config = {})
      sanitize = Sanitize.new(config)
      sanitize.clean(html)
    end

    # Performs Sanitize#clean in place, returning _html_, or +nil+ if no changes
    # were made.
    def clean!(html, config = {})
      sanitize = Sanitize.new(config)
      sanitize.clean!(html)
    end

    # Encodes special HTML characters (<, >, ", ', and &) in _html_ as entity
    # references and returns the encoded string.
    def encode_html(html)
      str = html.dup

      # Encode special chars.
      ENTITY_MAP.each {|char, entity| str.gsub!(char, entity) }

      # Convert unencoded ampersands to entity references.
      str.gsub(REGEX_AMPERSAND, '&amp;')
    end
  end

end
