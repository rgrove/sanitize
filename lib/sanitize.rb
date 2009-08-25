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

gem 'nokogiri', '~> 1.3.3'

require 'nokogiri'
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
  REGEX_AMPERSAND = /&(?!(?:[a-z]+[0-9]{0,2}|#[0-9]+|#x[0-9a-f]+);)/i

  # Matches an attribute value that could be treated by a browser as a URL
  # with a protocol prefix, such as "http:" or "javascript:". Any string of zero
  # or more characters followed by a colon is considered a match, even if the
  # colon is encoded as an entity and even if it's an incomplete entity (which
  # IE6 and Opera will still parse).
  REGEX_PROTOCOL = /^([A-Za-z0-9\+\-\.\&\;\#\s]*?)(?:\:|&#0*58|&#x0*3a)/i

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
    fragment = Nokogiri::HTML::DocumentFragment.parse(html)

    fragment.traverse do |node|
      if node.comment?
        node.unlink unless @config[:allow_comments]
      elsif node.element?
        name = node.name.to_s.downcase

        # Delete any element that isn't in the whitelist.
        unless @config[:elements].include?(name)
          node.children.each { |n| node.add_previous_sibling(n) }
          node.unlink
          next
        end

        attr_whitelist = ((@config[:attributes][name] || []) +
            (@config[:attributes][:all] || [])).uniq

        if attr_whitelist.empty?
          # Delete all attributes from elements with no whitelisted
          # attributes.
          node.attribute_nodes.each { |attr| attr.remove }
        else
          # Delete any attribute that isn't in the whitelist for this element.
          node.attribute_nodes.each do |attr|
            attr.unlink unless attr_whitelist.include?(attr.name.downcase)
          end

          # Delete remaining attributes that use unacceptable protocols.
          if @config[:protocols].has_key?(name)
            protocol = @config[:protocols][name]

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
        if @config[:add_attributes].has_key?(name)
          @config[:add_attributes][name].each do |key, val|
            node[key] = val
          end
        end
      elsif node.cdata?
        node.replace(Nokogiri::XML::Text.new(node.text, node.document))
      end
    end

    result = fragment.to_xhtml(:encoding => 'UTF-8', :indent => 0).gsub(/>\n/, '>')
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
