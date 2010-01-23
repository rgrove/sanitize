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

require 'bacon'
require 'sanitize'

strings = {
  :basic => {
    :html       => '<b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script>',
    :default    => 'Lorem ipsum dolor sitamet alert("hello world");',
    :restricted => '<b>Lorem</b> ipsum <strong>dolor</strong> sitamet alert("hello world");',
    :basic      => '<b>Lorem</b> <a href="pants" rel="nofollow">ipsum</a> <a href="http://foo.com/" rel="nofollow"><strong>dolor</strong></a> sit<br />amet alert("hello world");',
    :relaxed    => '<b>Lorem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br />amet alert("hello world");'
  },

  :malformed => {
    :html       => 'Lo<!-- comment -->rem</b> <a href=pants title="foo>ipsum <a href="http://foo.com/"><strong>dolor</a></strong> sit<br/>amet <script>alert("hello world");',
    :default    => 'Lorem dolor sitamet alert("hello world");',
    :restricted => 'Lorem <strong>dolor</strong> sitamet alert("hello world");',
    :basic      => 'Lorem <a href="pants" rel="nofollow"><strong>dolor</strong></a> sit<br />amet alert("hello world");',
    :relaxed    => 'Lorem <a href="pants" title="foo&gt;ipsum &lt;a href="><strong>dolor</strong></a> sit<br />amet alert("hello world");'
  },

  :unclosed => {
    :html       => '<p>a</p><blockquote>b',
    :default    => 'ab',
    :restricted => 'ab',
    :basic      => '<p>a</p><blockquote>b</blockquote>',
    :relaxed    => '<p>a</p><blockquote>b</blockquote>'
  },

  :malicious => {
    :html       => '<b>Lo<!-- comment -->rem</b> <a href="javascript:pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <<foo>script>alert("hello world");</script>',
    :default    => 'Lorem ipsum dolor sitamet script&gt;alert("hello world");',
    :restricted => '<b>Lorem</b> ipsum <strong>dolor</strong> sitamet script&gt;alert("hello world");',
    :basic      => '<b>Lorem</b> <a rel="nofollow">ipsum</a> <a href="http://foo.com/" rel="nofollow"><strong>dolor</strong></a> sit<br />amet script&gt;alert("hello world");',
    :relaxed    => '<b>Lorem</b> <a title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br />amet script&gt;alert("hello world");'
  },

  :raw_comment => {
    :html       => '<!-- comment -->Hello',
    :default    => 'Hello',
    :restricted => 'Hello',
    :basic      => 'Hello',
    :relaxed    => 'Hello'
  }
}

tricky = {
  'protocol-based JS injection: simple, no spaces' => {
    :html       => '<a href="javascript:alert(\'XSS\');">foo</a>',
    :default    => 'foo',
    :restricted => 'foo',
    :basic      => '<a rel="nofollow">foo</a>',
    :relaxed    => '<a>foo</a>'
  },

  'protocol-based JS injection: simple, spaces before' => {
    :html       => '<a href="javascript    :alert(\'XSS\');">foo</a>',
    :default    => 'foo',
    :restricted => 'foo',
    :basic      => '<a rel="nofollow">foo</a>',
    :relaxed    => '<a>foo</a>'
  },

  'protocol-based JS injection: simple, spaces after' => {
    :html       => '<a href="javascript:    alert(\'XSS\');">foo</a>',
    :default    => 'foo',
    :restricted => 'foo',
    :basic      => '<a rel="nofollow">foo</a>',
    :relaxed    => '<a>foo</a>'
  },

  'protocol-based JS injection: simple, spaces before and after' => {
    :html       => '<a href="javascript    :   alert(\'XSS\');">foo</a>',
    :default    => 'foo',
    :restricted => 'foo',
    :basic      => '<a rel="nofollow">foo</a>',
    :relaxed    => '<a>foo</a>'
  },

  'protocol-based JS injection: preceding colon' => {
    :html       => '<a href=":javascript:alert(\'XSS\');">foo</a>',
    :default    => 'foo',
    :restricted => 'foo',
    :basic      => '<a rel="nofollow">foo</a>',
    :relaxed    => '<a>foo</a>'
  },

  'protocol-based JS injection: UTF-8 encoding' => {
    :html       => '<a href="javascript&#58;">foo</a>',
    :default    => 'foo',
    :restricted => 'foo',
    :basic      => '<a rel="nofollow">foo</a>',
    :relaxed    => '<a>foo</a>'
  },

  'protocol-based JS injection: long UTF-8 encoding' => {
    :html       => '<a href="javascript&#0058;">foo</a>',
    :default    => 'foo',
    :restricted => 'foo',
    :basic      => '<a rel="nofollow">foo</a>',
    :relaxed    => '<a>foo</a>'
  },

  'protocol-based JS injection: long UTF-8 encoding without semicolons' => {
    :html       => '<a href=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>foo</a>',
    :default    => 'foo',
    :restricted => 'foo',
    :basic      => '<a rel="nofollow">foo</a>',
    :relaxed    => '<a>foo</a>'
  },

  'protocol-based JS injection: hex encoding' => {
    :html       => '<a href="javascript&#x3A;">foo</a>',
    :default    => 'foo',
    :restricted => 'foo',
    :basic      => '<a rel="nofollow">foo</a>',
    :relaxed    => '<a>foo</a>'
  },

  'protocol-based JS injection: long hex encoding' => {
    :html       => '<a href="javascript&#x003A;">foo</a>',
    :default    => 'foo',
    :restricted => 'foo',
    :basic      => '<a rel="nofollow">foo</a>',
    :relaxed    => '<a>foo</a>'
  },

  'protocol-based JS injection: hex encoding without semicolons' => {
    :html       => '<a href=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>foo</a>',
    :default    => 'foo',
    :restricted => 'foo',
    :basic      => '<a rel="nofollow">foo</a>',
    :relaxed    => '<a>foo</a>'
  }
}

describe 'Config::DEFAULT' do
  should 'translate valid HTML entities' do
    Sanitize.clean("Don&apos;t tas&eacute; me &amp; bro!").should.equal("Don't tasé me &amp; bro!")
  end

  should 'translate valid HTML entities while encoding unencoded ampersands' do
    Sanitize.clean("cookies&sup2; & &frac14; cr&eacute;me").should.equal("cookies² &amp; ¼ créme")
  end

  should 'never output &apos;' do
    Sanitize.clean("<a href='&apos;' class=\"' &#39;\">IE6 isn't a real browser</a>").should.not.match(/&apos;/)
  end

  should 'not choke on several instances of the same element in a row' do
    Sanitize.clean('<img src="http://www.google.com/intl/en_ALL/images/logo.gif"><img src="http://www.google.com/intl/en_ALL/images/logo.gif"><img src="http://www.google.com/intl/en_ALL/images/logo.gif"><img src="http://www.google.com/intl/en_ALL/images/logo.gif">').should.equal('')
  end

  strings.each do |name, data|
    should "clean #{name} HTML" do
      Sanitize.clean(data[:html]).should.equal(data[:default])
    end
  end

  tricky.each do |name, data|
    should "not allow #{name}" do
      Sanitize.clean(data[:html]).should.equal(data[:default])
    end
  end
end

describe 'Config::RESTRICTED' do
  before { @s = Sanitize.new(Sanitize::Config::RESTRICTED) }

  strings.each do |name, data|
    should "clean #{name} HTML" do
      @s.clean(data[:html]).should.equal(data[:restricted])
    end
  end

  tricky.each do |name, data|
    should "not allow #{name}" do
      @s.clean(data[:html]).should.equal(data[:restricted])
    end
  end
end

describe 'Config::BASIC' do
  before { @s = Sanitize.new(Sanitize::Config::BASIC) }

  should 'not choke on valueless attributes' do
    @s.clean('foo <a href>foo</a> bar').should.equal('foo <a href="" rel="nofollow">foo</a> bar')
  end

  should 'downcase attribute names' do
    @s.clean('<a HREF="javascript:alert(\'foo\')">bar</a>').should.equal('<a rel="nofollow">bar</a>')
  end

  strings.each do |name, data|
    should "clean #{name} HTML" do
      @s.clean(data[:html]).should.equal(data[:basic])
    end
  end

  tricky.each do |name, data|
    should "not allow #{name}" do
      @s.clean(data[:html]).should.equal(data[:basic])
    end
  end
end

describe 'Config::RELAXED' do
  before { @s = Sanitize.new(Sanitize::Config::RELAXED) }

  should 'encode special chars in attribute values' do
    @s.clean('<a href="http://example.com" title="<b>&eacute;xamples</b> & things">foo</a>').should.equal('<a href="http://example.com" title="&lt;b&gt;&#xE9;xamples&lt;/b&gt; &amp; things">foo</a>')
  end

  strings.each do |name, data|
    should "clean #{name} HTML" do
      @s.clean(data[:html]).should.equal(data[:relaxed])
    end
  end

  tricky.each do |name, data|
    should "not allow #{name}" do
      @s.clean(data[:html]).should.equal(data[:relaxed])
    end
  end
end

describe 'Custom configs' do
  should 'allow attributes on all elements if whitelisted under :all' do
    input = '<p class="foo">bar</p>'

    Sanitize.clean(input).should.equal('bar')
    Sanitize.clean(input, {:elements => ['p'], :attributes => {:all => ['class']}}).should.equal(input)
    Sanitize.clean(input, {:elements => ['p'], :attributes => {'div' => ['class']}}).should.equal('<p>bar</p>')
    Sanitize.clean(input, {:elements => ['p'], :attributes => {'p' => ['title'], :all => ['class']}}).should.equal(input)
  end

  should 'allow comments' do
    input = 'foo <!-- bar --> baz'
    Sanitize.clean(input, :allow_comments => true).should.equal(input)
  end

  should 'allow relative URLs containing colons where the colon is not in the first path segment' do
    input = '<a href="/wiki/Special:Random">Random Page</a>'
    Sanitize.clean(input, { :elements => ['a'], :attributes => {'a' => ['href']}, :protocols => { 'a' => { 'href' => [:relative] }} }).should.equal(input)
  end

  should 'output HTML' do
    input = 'foo<br/>bar<br>baz'
    Sanitize.clean(input, :elements => ['br'], :output => :html).should.equal('foo<br>bar<br>baz')
  end
end

describe 'Sanitize.clean' do
  should 'not modify the input string' do
    input = '<b>foo</b>'
    Sanitize.clean(input)
    input.should.equal('<b>foo</b>')
  end

  should 'return a new string' do
    input = '<b>foo</b>'
    Sanitize.clean(input).should.equal('foo')
  end
end

describe 'Sanitize.clean!' do
  should 'modify the input string' do
    input = '<b>foo</b>'
    Sanitize.clean!(input)
    input.should.equal('foo')
  end

  should 'return the string if it was modified' do
    input = '<b>foo</b>'
    Sanitize.clean!(input).should.equal('foo')
  end

  should 'return nil if the string was not modified' do
    input = 'foo'
    Sanitize.clean!(input).should.equal(nil)
  end
end

describe 'transformers' do
  # YouTube transformer.
  youtube = lambda do |env|
    node      = env[:node]
    node_name = node.name.to_s.downcase
    parent    = node.parent

    # Since the transformer receives the deepest nodes first, we look for a
    # <param> element or an <embed> element whose parent is an <object>.
    return nil unless (node_name == 'param' || node_name == 'embed') &&
        parent.name.to_s.downcase == 'object'

    if node_name == 'param'
      # Quick XPath search to find the <param> node that contains the video URL.
      return nil unless movie_node = parent.search('param[@name="movie"]')[0]
      url = movie_node['value']
    else
      # Since this is an <embed>, the video URL is in the "src" attribute. No
      # extra work needed.
      url = node['src']
    end

    # Verify that the video URL is actually a valid YouTube video URL.
    return nil unless url =~ /^http:\/\/(?:www\.)?youtube\.com\/v\//

    # We're now certain that this is a YouTube embed, but we still need to run
    # it through a special Sanitize step to ensure that no unwanted elements or
    # attributes that don't belong in a YouTube embed can sneak in.
    Sanitize.clean_node!(parent, {
      :elements   => ['embed', 'object', 'param'],
      :attributes => {
        'embed'  => ['allowfullscreen', 'allowscriptaccess', 'height', 'src', 'type', 'width'],
        'object' => ['height', 'width'],
        'param'  => ['name', 'value']
      }
    })

    # Now that we're sure that this is a valid YouTube embed and that there are
    # no unwanted elements or attributes hidden inside it, we can tell Sanitize
    # to whitelist the current node (<param> or <embed>) and its parent
    # (<object>).
    {:whitelist_nodes => [node, parent]}
  end

  should 'allow youtube video embeds via the youtube transformer' do
    input  = '<div><object foo="bar" height="344" width="425"><b>test</b><param foo="bar" name="movie" value="http://www.youtube.com/v/a1Y73sPHKxw&hl=en&fs=1&"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/a1Y73sPHKxw&hl=en&fs=1&" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="425" height="344"></embed></object></div>'
    output = Nokogiri::HTML::DocumentFragment.parse('<object height="344" width="425">test<param name="movie" value="http://www.youtube.com/v/a1Y73sPHKxw&hl=en&fs=1&"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/a1Y73sPHKxw&hl=en&fs=1&" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="425" height="344"></embed></object>').to_xhtml(:encoding => 'utf-8', :indent => 0, :save_with => Nokogiri::XML::Node::SaveOptions::AS_XHTML)

    Sanitize.clean!(input, :transformers => youtube).should.equal(output)
  end

  should 'not allow non-youtube video embeds via the youtube transformer' do
    input  = '<div><object height="344" width="425"><param name="movie" value="http://www.eviltube.com/v/a1Y73sPHKxw&hl=en&fs=1&"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.eviltube.com/v/a1Y73sPHKxw&hl=en&fs=1&" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="425" height="344"></embed></object></div>'
    output = ''

    Sanitize.clean!(input, :transformers => youtube).should.equal(output)
  end

  should 'raise Sanitize::Error when a transformer returns something silly' do
    should.raise(Sanitize::Error) do
      Sanitize.clean!('<b>foo</b>', :transformers => lambda { 'hello' })
    end
  end
end
