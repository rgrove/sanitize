# encoding: utf-8
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

require 'nokogiri'
require 'sanitize/version'
require 'sanitize/config'
require 'sanitize/config/restricted'
require 'sanitize/config/basic'
require 'sanitize/config/relaxed'

class Sanitize

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
        # Temporary node-specific whitelists provided by transformers.
        transformer_whitelist      = false
        transformer_attr_whitelist = []

        # Call transformers first, if any.
        transformer_result = @config[:transformers].inject(node) do |transformer_node, transformer|
          result = transformer.call({
            :config    => @config,
            :fragment  => fragment,
            :node      => transformer_node,
            :node_name => transformer_node.name.to_s.downcase
          })

          if result.nil?
            transformer_node
          elsif result.is_a?(Hash)
            transformer_whitelist = true if result[:whitelist]
            transformer_attr_whitelist += result[:attr_whitelist] if result[:attr_whitelist].is_a?(Array)
            result[:node].is_a?(Nokogiri::XML::Node) ? result[:node] : transformer_node
          else
            raise Error, "transformer return value must be a Hash or nil"
          end
        end

        if transformer_result.is_a?(Nokogiri::XML::Node) &&
            node != transformer_result
          node.replace(transformer_result)
        end
        
        name = node.name.to_s.downcase

        # Delete any element that isn't in the whitelist.
        unless transformer_whitelist || @config[:elements].include?(name)
          node.children.each { |n| node.add_previous_sibling(n) }
          node.unlink
          next
        end

        attr_whitelist = ((@config[:attributes][name] || []) +
            (@config[:attributes][:all] || []) +
            transformer_attr_whitelist).uniq

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

    if @config[:output] == :xhtml
      output_method = fragment.method(:to_xhtml)
    elsif @config[:output] == :html
      output_method = fragment.method(:to_html)
    else
      raise Error, "unsupported output format: #{@config[:output]}"
    end

    if RUBY_VERSION >= '1.9'
      # Nokogiri 1.3.3 (and possibly earlier versions) always returns a US-ASCII
      # string no matter what we ask for. This will be fixed in 1.4.0, but for
      # now we have to hack around it to prevent errors.
      result = output_method.call(:encoding => 'utf-8', :indent => 0).force_encoding('utf-8')
      result.gsub!(">\n", '>')
    else
      result = output_method.call(:encoding => 'utf-8', :indent => 0).gsub(">\n", '>')
    end

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
  end

end
