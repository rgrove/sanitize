# encoding: utf-8
#--
# Copyright (c) 2011 Ryan Grove <ryan@wonko.com>
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
require 'sanitize/transformers/clean_cdata'
require 'sanitize/transformers/clean_comment'
require 'sanitize/transformers/clean_element'

class Sanitize
  attr_reader :config

  # Matches an attribute value that could be treated by a browser as a URL
  # with a protocol prefix, such as "http:" or "javascript:". Any string of zero
  # or more characters followed by a colon is considered a match, even if the
  # colon is encoded as an entity and even if it's an incomplete entity (which
  # IE6 and Opera will still parse).
  REGEX_PROTOCOL = /\A([^\/]*?)(?:\:|&#0*58|&#x0*3a)/i

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
    @config = Config::DEFAULT.merge(config)

    @transformers = {
      :breadth => Array(@config[:transformers_breadth].dup),
      :depth   => Array(@config[:transformers]) + Array(@config[:transformers_depth])
    }

    # Default depth transformers. These always run at the end of the chain,
    # after any custom transformers.
    @transformers[:depth] << Transformers::CleanComment unless @config[:allow_comments]

    @transformers[:depth] <<
        Transformers::CleanCDATA <<
        Transformers::CleanElement.new(@config)
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

    node_whitelist = Set.new

    unless @transformers[:breadth].empty?
      traverse_breadth(node) {|n| transform_node!(n, node_whitelist, :breadth) }
    end

    traverse_depth(node) {|n| transform_node!(n, node_whitelist, :depth) }
    node
  end

  private

  def transform_node!(node, node_whitelist, mode)
    @transformers[mode].each do |transformer|
      result = transformer.call({
        :config         => @config,
        :is_whitelisted => node_whitelist.include?(node),
        :node           => node,
        :node_name      => node.name.downcase,
        :node_whitelist => node_whitelist,
        :traversal_mode => mode
      })

      if result.is_a?(Hash) && result[:node_whitelist].respond_to?(:each)
        node_whitelist.merge(result[:node_whitelist])
      end
    end

    node
  end

  # Performs breadth-first traversal, operating first on the root node, then
  # traversing downwards.
  def traverse_breadth(node, &block)
    block.call(node)
    node.children.each {|child| traverse_breadth(child, &block) }
  end

  # Performs depth-first traversal, operating first on the deepest nodes in the
  # document, then traversing upwards to the root.
  def traverse_depth(node, &block)
    node.children.each {|child| traverse_depth(child, &block) }
    block.call(node)
  end

  class Error < StandardError; end
end
