# encoding: utf-8
#--
# Copyright (c) 2010 Ryan Grove <ryan@wonko.com>
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

require 'set'

require 'nokogiri'
require 'sanitize/version'
require 'sanitize/config'
require 'sanitize/config/restricted'
require 'sanitize/config/basic'
require 'sanitize/config/relaxed'
require 'sanitize/transformers/clean_element'

class Sanitize
  attr_reader :config

  # Matches an attribute value that could be treated by a browser as a URL
  # with a protocol prefix, such as "http:" or "javascript:". Any string of zero
  # or more characters followed by a colon is considered a match, even if the
  # colon is encoded as an entity and even if it's an incomplete entity (which
  # IE6 and Opera will still parse).
  REGEX_PROTOCOL = /^([A-Za-z0-9\+\-\.\&\;\#\s]*?)(?:\:|&#0*58|&#x0*3a)/i

  #--
  # Class Methods
  #++

  # Returns a sanitized copy of _html_, using the settings in _config_ if
  # specified.
  def self.clean(html, config = {})
    Sanitize.new(config).clean(html)
  end

  # Performs Sanitize#clean in place, returning _html_, or +nil+ if no changes
  # were made.
  def self.clean!(html, config = {})
    Sanitize.new(config).clean!(html)
  end

  # Sanitizes the specified Nokogiri::XML::Node and all its children.
  def self.clean_node!(node, config = {})
    Sanitize.new(config).clean_node!(node)
  end

  #--
  # Instance Methods
  #++

  # Returns a new Sanitize object initialized with the settings in _config_.
  def initialize(config = {})
    # Sanitize configuration.
    @config = Config::DEFAULT.merge(config)
    @transformers = Array(@config[:transformers].dup)

    # Default transformers.
    @transformers << Transformers::CleanElement.new(@config)

    # Specific nodes to whitelist (along with all their attributes). This array
    # is generated at runtime by transformers, and is cleared before and after
    # a fragment is cleaned (so it applies only to a specific fragment).
    @whitelist_nodes = []
  end

  # Returns a sanitized copy of _html_.
  def clean(html)
    if html
      dupe = html.dup
      clean!(dupe) || dupe
    end
  end

  # Performs clean in place, returning _html_, or +nil+ if no changes were
  # made.
  def clean!(html)
    fragment = Nokogiri::HTML::DocumentFragment.parse(html)
    clean_node!(fragment)

    output_method_params = {:encoding => @config[:output_encoding], :indent => 0}

    if @config[:output] == :xhtml
      output_method = fragment.method(:to_xhtml)
      output_method_params[:save_with] = Nokogiri::XML::Node::SaveOptions::AS_XHTML
    elsif @config[:output] == :html
      output_method = fragment.method(:to_html)
    else
      raise Error, "unsupported output format: #{@config[:output]}"
    end

    result = output_method.call(output_method_params)

    return result == html ? nil : html[0, html.length] = result
  end

  # Sanitizes the specified Nokogiri::XML::Node and all its children.
  def clean_node!(node)
    raise ArgumentError unless node.is_a?(Nokogiri::XML::Node)

    node.traverse do |child|
    # traverse(node) do |child|
      if child.element? || (child.text? && @config[:process_text_nodes])
        clean_element!(child)
      elsif child.comment?
        child.unlink unless @config[:allow_comments]
      elsif child.cdata?
        child.replace(Nokogiri::XML::Text.new(child.text, child.document))
      end
    end

    node
  end

  private

  # def traverse(node, &block)
  #   block.call(node)
  #   node.children.each {|child| traverse(child, &block)} if node
  # end

  def clean_element!(node)
    # Run this node through all configured transformers.
    transform = transform_element!(node)

    # # If this node is in the dynamic whitelist array (built at runtime by
    # # transformers), let it live with all of its attributes intact.
    # return if @whitelist_nodes.include?(node)

    transform
  end

  def transform_element!(node)
    document = node.document

    attr_whitelist = Set.new
    node_whitelist = Set.new

    # TODO: node_whitelist needs to be a global whitelist, persistent during the
    # current clean operation (not just the current node transform).
    #
    # But we also need a way of adding the current node to the local whitelist,
    # as if it were in :allowed_elements.
    #
    # Or maybe we should only ever allow local whitelisting and never global
    # persistent whitelisting. Hmm.

    @transformers.each do |transformer|
      result = transformer.call({
        :attr_whitelist => attr_whitelist,
        :config         => @config,
        :node           => node,
        :node_name      => node.name.downcase,
        :node_whitelist => node_whitelist
      })

      # If the node has been destroyed or removed from the document, there's no
      # point running subsequent transformers.
      break unless node && node.document == document

      if result.is_a?(Hash)
        attr_whitelist.merge(result[:attr_whitelist]) if result[:attr_whitelist].respond_to?(:each)
        node_whitelist.merge(result[:node_whitelist]) if result[:node_whitelist].respond_to?(:each)
      end
    end

    node
  end

  class Error < StandardError; end
end
