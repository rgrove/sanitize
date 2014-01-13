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

  # Matches a valid HTML5 data attribute name. The unicode ranges included here
  # are a conservative subset of the full range of characters that are
  # technically allowed, with the intent of matching the most common characters
  # used in data attribute names while excluding uncommon or potentially
  # misleading characters, or characters with the potential to be normalized
  # into unsafe or confusing forms.
  #
  # If you need data attr names with characters that aren't included here (such
  # as combining marks, full-width characters, or CJK), please consider creating
  # a custom transformer to validate attributes according to your needs.
  #
  # http://www.whatwg.org/specs/web-apps/current-work/multipage/elements.html#embedding-custom-non-visible-data-with-the-data-*-attributes
  REGEX_DATA_ATTR = /\Adata-(?!xml)[a-z_][\w.\u00E0-\u00F6\u00F8-\u017F\u01DD-\u02AF-]*\z/u

  # Matches an attribute value that could be treated by a browser as a URL
  # with a protocol prefix, such as "http:" or "javascript:". Any string of zero
  # or more characters followed by a colon is considered a match, even if the
  # colon is encoded as an entity and even if it's an incomplete entity (which
  # IE6 and Opera will still parse).
  REGEX_PROTOCOL = /\A([^\/#]*?)(?:\:|&#0*58|&#x0*3a)/i

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

  # Returns a sanitized copy of the given _html_ document.
  #
  # When sanitizing a document, the `<html>` element must be whitelisted or an
  # error will be raised. If this is undesirable, you should probably use
  # {#fragment} instead.
  def document(html, parser = Nokogiri::HTML::Document)
    return '' unless html

    doc = parser.parse(html)
    node!(doc)
    to_html(doc)
  end

  # Returns a sanitized copy of the given _html_ fragment.
  def fragment(html, parser = Nokogiri::HTML::Document)
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

    unless @transformers[:breadth].empty?
      traverse_breadth(node) {|n| transform_node!(n, node_whitelist, :breadth) }
    end

    traverse_depth(node) {|n| transform_node!(n, node_whitelist, :depth) }
    node
  end

  private

  def to_html(node)
    node.to_html(
      :encoding => @config[:output_encoding],
      :indent   => 0
    )
  end

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
