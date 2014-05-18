# encoding: utf-8
#--
# Copyright (c) 2013 Ryan Grove <ryan@wonko.com>
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

require 'nokogumbo'
require 'set'

require_relative 'sanitize/version'
require_relative 'sanitize/config/default'
require_relative 'sanitize/config/restricted'
require_relative 'sanitize/config/basic'
require_relative 'sanitize/config/relaxed'
require_relative 'sanitize/transformers/clean_cdata'
require_relative 'sanitize/transformers/clean_comment'
require_relative 'sanitize/transformers/clean_element'

class Sanitize
  attr_reader :config

  #--
  # Class Methods
  #++

  # Returns a sanitized copy of the given full _html_ document, using the
  # settings in _config_ if specified.
  #
  # When sanitizing a document, the `<html>` element must be whitelisted or an
  # error will be raised. If this is undesirable, you should probably use
  # {#fragment} instead.
  def self.document(html, config = {})
    Sanitize.new(config).document(html)
  end

  # Returns a sanitized copy of the given _html_ fragment, using the settings in
  # _config_ if specified.
  def self.fragment(html, config = {})
    Sanitize.new(config).fragment(html)
  end

  # Sanitizes the given `Nokogiri::XML::Node` instance and all its children.
  def self.node!(node, config = {})
    Sanitize.new(config).node!(node)
  end

  #--
  # Instance Methods
  #++

  # Returns a new Sanitize object initialized with the settings in _config_.
  def initialize(config = {})
    @config = Config::DEFAULT.merge(config)

    @transformers = Array(@config[:transformers].dup)

    # Default transformers always run at the end of the chain, after any custom
    # transformers.
    @transformers << Transformers::CleanComment unless @config[:allow_comments]

    @transformers <<
        Transformers::CleanCDATA <<
        Transformers::CleanElement.new(@config)
  end

  # Returns a sanitized copy of the given _html_ document.
  #
  # When sanitizing a document, the `<html>` element must be whitelisted or an
  # error will be raised. If this is undesirable, you should probably use
  # {#fragment} instead.
  def document(html, parser = Nokogiri::HTML5)
    return '' unless html

    doc = parser.parse(html)
    node!(doc)
    to_html(doc)
  end

  # Returns a sanitized copy of the given _html_ fragment.
  def fragment(html, parser = Nokogiri::HTML5)
    return '' unless html

    doc = parser.parse("<html><body>#{html}")

    # Hack to allow fragments containing <body>. Borrowed from
    # Nokogiri::HTML::DocumentFragment.
    if html =~ /\A<body(?:\s|>)/i
      path = '/html/body'
    else
      path = '/html/body/node()'
    end

    frag = doc.fragment
    doc.xpath(path).each {|node| frag << node }

    node!(frag)
    to_html(frag)
  end

  # Sanitizes the given `Nokogiri::XML::Node` and all its children, modifying it
  # in place.
  #
  # If _node_ is a `Nokogiri::XML::Document`, the `<html>` element must be
  # whitelisted or an error will be raised.
  def node!(node)
    raise ArgumentError unless node.is_a?(Nokogiri::XML::Node)

    if node.is_a?(Nokogiri::XML::Document)
      unless @config[:elements].include?('html')
        raise Error, 'When sanitizing a document, "<html>" must be whitelisted.'
      end
    end

    node_whitelist = Set.new

    traverse(node) do |n|
      transform_node!(n, node_whitelist)
    end

    node
  end

  private

  def to_html(node)
    node.to_html(
      :encoding => 'utf-8',
      :indent   => 0
    )
  end

  def transform_node!(node, node_whitelist)
    @transformers.each do |transformer|
      result = transformer.call({
        :config         => @config,
        :is_whitelisted => node_whitelist.include?(node),
        :node           => node,
        :node_name      => node.name.downcase,
        :node_whitelist => node_whitelist,
      })

      if result.is_a?(Hash) && result[:node_whitelist].respond_to?(:each)
        node_whitelist.merge(result[:node_whitelist])
      end
    end

    node
  end

  # Performs top-down traversal of the given node, operating first on the node
  # itself, then traversing each child (if any) in order.
  def traverse(node, &block)
    block.call(node)

    child = node.child

    while child do
      prev = child.previous_sibling
      traverse(child, &block)

      if child.parent != node
        # The child was unlinked or reparented, so traverse the previous node's
        # next sibling, or the parent's first child if there is no previous
        # node.
        child = prev ? prev.next_sibling : node.child
      else
        child = child.next_sibling
      end
    end
  end

  class Error < StandardError; end
end
