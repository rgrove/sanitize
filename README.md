Sanitize
========

Sanitize is a whitelist-based HTML sanitizer. Given a list of acceptable
elements and attributes, Sanitize will remove all unacceptable HTML from a
string.

Using a simple configuration syntax, you can tell Sanitize to allow certain
elements, certain attributes within those elements, and even certain URL
protocols within attributes that contain URLs. Any HTML elements or attributes
that you don't explicitly allow will be removed.

Because it's based on Nokogiri, a full-fledged HTML parser, rather than a bunch
of fragile regular expressions, Sanitize has no trouble dealing with malformed
or maliciously-formed HTML and returning safe output.

[![Build Status](https://travis-ci.org/rgrove/sanitize.png?branch=master)](https://travis-ci.org/rgrove/sanitize?branch=master)

Installation
-------------

```
gem install sanitize
```

Usage
-----

If you don't specify any configuration options, Sanitize will use its strictest
settings by default, which means it will strip all HTML and leave only text
behind.

```ruby
require 'rubygems'
require 'sanitize'

html = '<b><a href="http://foo.com/">foo</a></b><img src="http://foo.com/bar.jpg">'

Sanitize.clean(html) # => 'foo'

# or sanitize an entire HTML document (example assumes _html_ is whitelisted)
html = '<!DOCTYPE html><html><b><a href="http://foo.com/">foo</a></b><img src="http://foo.com/bar.jpg"></html>'
Sanitize.clean_document(html) # => '<!DOCTYPE html>\n<html>foo</html>\n'
```

Configuration
-------------

In addition to the ultra-safe default settings, Sanitize comes with three other
built-in modes.

### Sanitize::Config::RESTRICTED

Allows only very simple inline formatting markup. No links, images, or block
elements.

```ruby
Sanitize.clean(html, Sanitize::Config::RESTRICTED) # => '<b>foo</b>'
```

### Sanitize::Config::BASIC

Allows a variety of markup including formatting tags, links, and lists. Images
and tables are not allowed, links are limited to FTP, HTTP, HTTPS, and mailto
protocols, and a `rel="nofollow"` attribute is added to all links to
mitigate SEO spam.

```ruby
Sanitize.clean(html, Sanitize::Config::BASIC)
# => '<b><a href="http://foo.com/" rel="nofollow">foo</a></b>'
```

### Sanitize::Config::RELAXED

Allows an even wider variety of markup than BASIC, including images and tables.
Links are still limited to FTP, HTTP, HTTPS, and mailto protocols, while images
are limited to HTTP and HTTPS. In this mode, `rel="nofollow"` is not added to
links.

```ruby
Sanitize.clean(html, Sanitize::Config::RELAXED)
# => '<b><a href="http://foo.com/">foo</a></b><img src="http://foo.com/bar.jpg">'
```

### Custom Configuration

If the built-in modes don't meet your needs, you can easily specify a custom
configuration:

```ruby
Sanitize.clean(html, :elements => ['a', 'span'],
    :attributes => {'a' => ['href', 'title'], 'span' => ['class']},
    :protocols => {'a' => {'href' => ['http', 'https', 'mailto']}})
```

#### :add_attributes (Hash)

Attributes to add to specific elements. If the attribute already exists, it will
be replaced with the value specified here. Specify all element names and
attributes in lowercase.

```ruby
:add_attributes => {
  'a' => {'rel' => 'nofollow'}
}
```

#### :allow_comments (boolean)

Whether or not to allow HTML comments. Allowing comments is strongly
discouraged, since IE allows script execution within conditional comments. The
default value is `false`.

#### :attributes (Hash)

Attributes to allow for specific elements. Specify all element names and
attributes in lowercase.

```ruby
:attributes => {
  'a'          => ['href', 'title'],
  'blockquote' => ['cite'],
  'img'        => ['alt', 'src', 'title']
}
```

If you'd like to allow certain attributes on all elements, use the symbol
`:all` instead of an element name.

```ruby
# Allow the class attribute on all elements.
:attributes => {
  :all => ['class'],
  'a'  => ['href', 'title']
}
```

To allow arbitrary HTML5 `data-*` attributes, use the symbol
`:data` in place of an attribute name.

```ruby
# Allow arbitrary HTML5 data-* attributes on <div> elements.
:attributes => {
  'div' => [:data]
}
```

#### :elements (Array)

Array of element names to allow. Specify all names in lowercase.

```ruby
:elements => %w[
  a abbr b blockquote br cite code dd dfn dl dt em i kbd li mark ol p pre
  q s samp small strike strong sub sup time u ul var
]
```

#### :output (Symbol)

Output format. Supported formats are `:html` and `:xhtml`,
defaulting to `:html`.

#### :output_encoding (String)

Character encoding to use for HTML output. Default is `utf-8`.

#### :protocols (Hash)

URL protocols to allow in specific attributes. If an attribute is listed here
and contains a protocol other than those specified (or if it contains no
protocol at all), it will be removed.

```ruby
:protocols => {
  'a'   => {'href' => ['ftp', 'http', 'https', 'mailto']},
  'img' => {'src'  => ['http', 'https']}
}
```

If you'd like to allow the use of relative URLs which don't have a protocol,
include the symbol `:relative` in the protocol array:

```ruby
:protocols => {
  'a' => {'href' => ['http', 'https', :relative]}
}
```

#### :remove_contents (boolean or Array)

If set to +true+, Sanitize will remove the contents of any non-whitelisted
elements in addition to the elements themselves. By default, Sanitize leaves the
safe parts of an element's contents behind when the element is removed.

If set to an array of element names, then only the contents of the specified
elements (when filtered) will be removed, and the contents of all other filtered
elements will be left behind.

The default value is `false`.

#### :transformers

Custom transformer or array of custom transformers to run using depth-first
traversal. See the Transformers section below for details.

#### :transformers_breadth

Custom transformer or array of custom transformers to run using breadth-first
traversal. See the Transformers section below for details.

#### :whitespace_elements (Array)

Array of lowercase element names that should be replaced with whitespace when
removed in order to preserve readability. For example,
`foo<div>bar</div>baz` will become
`foo bar baz` when the `<div>` is removed.

By default, the following elements are included in the
`:whitespace_elements` array:

```
address article aside blockquote br dd div dl dt footer h1 h2 h3 h4 h5
h6 header hgroup hr li nav ol p pre section ul
```

### Transformers

Transformers allow you to filter and modify nodes using your own custom logic,
on top of (or instead of) Sanitize's core filter. A transformer is any object
that responds to `call()` (such as a lambda or proc).

To use one or more transformers, pass them to the `:transformers`
config setting. You may pass a single transformer or an array of transformers.

```ruby
Sanitize.clean(html, :transformers => [transformer_one, transformer_two])
```

#### Input

Each registered transformer's `call()` method will be called once for
each node in the HTML (including elements, text nodes, comments, etc.), and will
receive as an argument an environment Hash that contains the following items:

  * **:config** - The current Sanitize configuration Hash.

  * **:is_whitelisted** - `true` if the current node has been whitelisted by a
    previous transformer, `false` otherwise. It's generally bad form to remove
    a node that a previous transformer has whitelisted.

  * **:node** - A `Nokogiri::XML::Node` object representing an HTML node. The
    node may be an element, a text node, a comment, a CDATA node, or a document
    fragment. Use Nokogiri's inspection methods (`element?`, `text?`, etc.) to
    selectively ignore node types you aren't interested in.

  * **:node_name** - The name of the current HTML node, always lowercase (e.g.
    "div" or "span"). For non-element nodes, the name will be something like
    "text", "comment", "#cdata-section", "#document-fragment", etc.

  * **:node_whitelist** - Set of `Nokogiri::XML::Node` objects in the current
    document that have been whitelisted by previous transformers, if any. It's
    generally bad form to remove a node that a previous transformer has
    whitelisted.

  * **:traversal_mode** - Current node traversal mode, either `:depth` for
    depth-first (the default mode) or `:breadth` for breadth-first.

#### Output

A transformer doesn't have to return anything, but may optionally return a Hash,
which may contain the following items:

  * **:node_whitelist** -  Array or Set of specific Nokogiri::XML::Node objects
    to add to the document's whitelist, bypassing the current Sanitize config.
    These specific nodes and all their attributes will be whitelisted, but
    their children will not be.

If a transformer returns anything other than a Hash, the return value will be
ignored.

#### Processing

Each transformer has full access to the `Nokogiri::XML::Node` that's passed into
it and to the rest of the document via the node's `document()` method. Any
changes made to the current node or to the document will be reflected instantly
in the document and passed on to subsequently called transformers and to
Sanitize itself. A transformer may even call Sanitize internally to perform
custom sanitization if needed.

Nodes are passed into transformers in the order in which they're traversed. By
default, depth-first traversal is used, meaning that markup is traversed from
the deepest node upward (not from the first node to the last node):

```ruby
html        = '<div><span>foo</span></div>'
transformer = lambda{|env| puts env[:node_name] }

# Prints "text", "span", "div", "#document-fragment".
Sanitize.clean(html, :transformers => transformer)
```

You may use the `:transformers_breadth` config to specify one or more
transformers that should traverse nodes in breadth-first mode:

```ruby
html        = '<div><span>foo</span></div>'
transformer = lambda{|env| puts env[:node_name] }

# Prints "#document-fragment", "div", "span", "text".
Sanitize.clean(html, :transformers_breadth => transformer)
```

Transformers have a tremendous amount of power, including the power to
completely bypass Sanitize's built-in filtering. Be careful! Your safety is in
your own hands.

#### Example: Transformer to whitelist YouTube video embeds

The following example demonstrates how to create a depth-first Sanitize
transformer that will safely whitelist valid YouTube video embeds without having
to blindly allow other kinds of embedded content, which would be the case if you
tried to do this by just whitelisting all `<iframe>` elements:

```ruby
lambda do |env|
  node      = env[:node]
  node_name = env[:node_name]

  # Don't continue if this node is already whitelisted or is not an element.
  return if env[:is_whitelisted] || !node.element?

  # Don't continue unless the node is an iframe.
  return unless node_name == 'iframe'

  # Verify that the video URL is actually a valid YouTube video URL.
  return unless node['src'] =~ /\A(https?:)?\/\/(?:www\.)?youtube(?:-nocookie)?\.com\//

  # We're now certain that this is a YouTube embed, but we still need to run
  # it through a special Sanitize step to ensure that no unwanted elements or
  # attributes that don't belong in a YouTube embed can sneak in.
  Sanitize.clean_node!(node, {
    :elements => %w[iframe],

    :attributes => {
      'iframe'  => %w[allowfullscreen frameborder height src width]
    }
  })

  # Now that we're sure that this is a valid YouTube embed and that there are
  # no unwanted elements or attributes hidden inside it, we can tell Sanitize
  # to whitelist the current node.
  {:node_whitelist => [node]}
end
```

Contributors
------------

Sanitize was created and is maintained by Ryan Grove (ryan@wonko.com).

The following lovely people have also contributed to Sanitize:

* Ben Anderson
* Wilson Bilkovich
* Peter Cooper
* Gabe da Silveira
* Nicholas Evans
* Nils Gemeinhardt
* Adam Hooper
* Mutwin Kraus
* Eaden McKee
* Dev Purkayastha
* David Reese
* Ardie Saeidi
* Rafael Souza
* Ben Wanicur

License
-------

Copyright (c) 2014 Ryan Grove (ryan@wonko.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the 'Software'), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
