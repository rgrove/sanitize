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

require 'rubygems'
gem 'minitest'

require 'minitest/autorun'
require 'sanitize'

strings = {
  :basic => {
    :html       => '<b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script>',
    :default    => 'Lorem ipsum dolor sit amet alert("hello world");',
    :restricted => '<b>Lorem</b> ipsum <strong>dolor</strong> sit amet alert("hello world");',
    :basic      => '<b>Lorem</b> <a href="pants" rel="nofollow">ipsum</a> <a href="http://foo.com/" rel="nofollow"><strong>dolor</strong></a> sit<br>amet alert("hello world");',
    :relaxed    => '<b>Lorem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br>amet alert("hello world");'
  },

  :malformed => {
    :html       => 'Lo<!-- comment -->rem</b> <a href=pants title="foo>ipsum <a href="http://foo.com/"><strong>dolor</a></strong> sit<br/>amet <script>alert("hello world");',
    :default    => 'Lorem dolor sit amet alert("hello world");',
    :restricted => 'Lorem <strong>dolor</strong> sit amet alert("hello world");',
    :basic      => 'Lorem <a href="pants" rel="nofollow"><strong>dolor</strong></a> sit<br>amet alert("hello world");',
    :relaxed    => 'Lorem <a href="pants" title="foo&gt;ipsum &lt;a href="><strong>dolor</strong></a> sit<br>amet alert("hello world");',
    :document   => ' Lorem dolor sit amet alert("hello world"); '
  },

  :unclosed => {
    :html       => '<p>a</p><blockquote>b',
    :default    => ' a  b ',
    :restricted => ' a  b ',
    :basic      => '<p>a</p><blockquote>b</blockquote>',
    :relaxed    => '<p>a</p><blockquote>b</blockquote>'
  },

  :malicious => {
    :html       => '<b>Lo<!-- comment -->rem</b> <a href="javascript:pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <<foo>script>alert("hello world");</script>',
    :default    => 'Lorem ipsum dolor sit amet script&gt;alert("hello world");',
    :restricted => '<b>Lorem</b> ipsum <strong>dolor</strong> sit amet script&gt;alert("hello world");',
    :basic      => '<b>Lorem</b> <a rel="nofollow">ipsum</a> <a href="http://foo.com/" rel="nofollow"><strong>dolor</strong></a> sit<br>amet script&gt;alert("hello world");',
    :relaxed    => '<b>Lorem</b> <a title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br>amet script&gt;alert("hello world");'
  },

  :raw_comment => {
    :html       => '<!-- comment -->Hello',
    :default    => 'Hello',
    :restricted => 'Hello',
    :basic      => 'Hello',
    :relaxed    => 'Hello',
    :document   => ' Hello ',
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
  },

  'protocol-based JS injection: null char' => {
    :html       => "<img src=java\0script:alert(\"XSS\")>",
    :default    => '',
    :restricted => '',
    :basic      => '',
    :relaxed    => '<img src="java">' # everything following the null char gets stripped, and URL is considered relative
  },

  'protocol-based JS injection: invalid URL char' => {
    :html       => '<img src=java\script:alert("XSS")>',
    :default    => '',
    :restricted => '',
    :basic      => '',
    :relaxed    => '<img>'
  },

  'protocol-based JS injection: spaces and entities' => {
    :html       => '<img src=" &#14;  javascript:alert(\'XSS\');">',
    :default    => '',
    :restricted => '',
    :basic      => '',
    :relaxed    => '<img src="">'
  }
}

describe 'Config::DEFAULT' do
  it 'should translate valid HTML entities' do
    Sanitize.clean("Don&apos;t tas&eacute; me &amp; bro!").must_equal("Don't tasé me &amp; bro!")
  end

  it 'should translate valid HTML entities while encoding unencoded ampersands' do
    Sanitize.clean("cookies&sup2; & &frac14; cr&eacute;me").must_equal("cookies² &amp; ¼ créme")
  end

  it 'should never output &apos;' do
    Sanitize.clean("<a href='&apos;' class=\"' &#39;\">IE6 isn't a real browser</a>").wont_match(/&apos;/)
  end

  it 'should not choke on several instances of the same element in a row' do
    Sanitize.clean('<img src="http://www.google.com/intl/en_ALL/images/logo.gif"><img src="http://www.google.com/intl/en_ALL/images/logo.gif"><img src="http://www.google.com/intl/en_ALL/images/logo.gif"><img src="http://www.google.com/intl/en_ALL/images/logo.gif">').must_equal('')
  end

  it 'should surround the contents of :whitespace_elements with space characters when removing the element' do
    Sanitize.clean('foo<div>bar</div>baz').must_equal('foo bar baz')
    Sanitize.clean('foo<br>bar<br>baz').must_equal('foo bar baz')
    Sanitize.clean('foo<hr>bar<hr>baz').must_equal('foo bar baz')
  end

  strings.each do |name, data|
    it "should clean #{name} HTML" do
      Sanitize.clean(data[:html]).must_equal(data[:default])
    end
  end

  tricky.each do |name, data|
    it "should not allow #{name}" do
      Sanitize.clean(data[:html]).must_equal(data[:default])
    end
  end
end

describe 'Config::RESTRICTED' do
  before { @s = Sanitize.new(Sanitize::Config::RESTRICTED) }

  strings.each do |name, data|
    it "should clean #{name} HTML" do
      @s.clean(data[:html]).must_equal(data[:restricted])
    end
  end

  tricky.each do |name, data|
    it "should not allow #{name}" do
      @s.clean(data[:html]).must_equal(data[:restricted])
    end
  end
end

describe 'Config::BASIC' do
  before { @s = Sanitize.new(Sanitize::Config::BASIC) }

  it 'should not choke on valueless attributes' do
    @s.clean('foo <a href>foo</a> bar').must_equal('foo <a href rel="nofollow">foo</a> bar')
  end

  it 'should downcase attribute names' do
    @s.clean('<a HREF="javascript:alert(\'foo\')">bar</a>').must_equal('<a rel="nofollow">bar</a>')
  end

  strings.each do |name, data|
    it "should clean #{name} HTML" do
      @s.clean(data[:html]).must_equal(data[:basic])
    end
  end

  tricky.each do |name, data|
    it "should not allow #{name}" do
      @s.clean(data[:html]).must_equal(data[:basic])
    end
  end
end

describe 'Config::RELAXED' do
  before { @s = Sanitize.new(Sanitize::Config::RELAXED) }

  it 'should encode special chars in attribute values' do
    input  = '<a href="http://example.com" title="<b>&eacute;xamples</b> & things">foo</a>'
    output = Nokogiri::HTML.fragment('<a href="http://example.com" title="&lt;b&gt;éxamples&lt;/b&gt; &amp; things">foo</a>').to_xhtml(:encoding => 'utf-8', :indent => 0, :save_with => Nokogiri::XML::Node::SaveOptions::AS_XHTML)
    @s.clean(input).must_equal(output)
  end

  strings.each do |name, data|
    it "should clean #{name} HTML" do
      @s.clean(data[:html]).must_equal(data[:relaxed])
    end
  end

  tricky.each do |name, data|
    it "should not allow #{name}" do
      @s.clean(data[:html]).must_equal(data[:relaxed])
    end
  end
end

describe 'Full Document parser (using clean_document)' do
  before {
    @s = Sanitize.new({:elements => %w[!DOCTYPE html]})
    @default_doctype = "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">"
  }

  it 'should require HTML element is whitelisted to prevent parser errors' do
    assert_raises(RuntimeError, 'You must have the HTML element whitelisted') {
      Sanitize.clean_document!('', {:elements => [], :remove_contents => false})
    }
  end

  it 'should NOT require HTML element to be whitelisted if remove_contents is true' do
    output = '<!DOCTYPE html><html>foo</html>'
    Sanitize.clean_document!(output, {:remove_contents => true}).must_equal "<!DOCTYPE html>\n\n"
  end

  it 'adds a doctype tag if not included' do
    @s.clean_document('').must_equal("#{@default_doctype}\n\n")
  end

  it 'should apply whitelist filtering to HTML element' do
    output = "<!DOCTYPE html>\n<html anything='false'></html>\n\n"
    @s.clean_document(output).must_equal("<!DOCTYPE html>\n<html></html>\n")
  end

  strings.each do |name, data|
    it "should wrap #{name} with DOCTYPE and HTML tag" do
      output = data[:document] || data[:default]
      @s.clean_document(data[:html]).must_equal("#{@default_doctype}\n<html>#{output}</html>\n")
    end
  end

  tricky.each do |name, data|
    it "should wrap #{name} with DOCTYPE and HTML tag" do
      @s.clean_document(data[:html]).must_equal("#{@default_doctype}\n<html>#{data[:default]}</html>\n")
    end
  end
end

describe 'Custom configs' do
  it 'should allow attributes on all elements if whitelisted under :all' do
    input = '<p class="foo">bar</p>'

    Sanitize.clean(input).must_equal(' bar ')
    Sanitize.clean(input, {:elements => ['p'], :attributes => {:all => ['class']}}).must_equal(input)
    Sanitize.clean(input, {:elements => ['p'], :attributes => {'div' => ['class']}}).must_equal('<p>bar</p>')
    Sanitize.clean(input, {:elements => ['p'], :attributes => {'p' => ['title'], :all => ['class']}}).must_equal(input)
  end

  it 'should allow comments when :allow_comments == true' do
    input = 'foo <!-- bar --> baz'
    Sanitize.clean(input).must_equal('foo  baz')
    Sanitize.clean(input, :allow_comments => true).must_equal(input)
  end

  it 'should allow relative URLs containing colons where the colon is not in the first path segment' do
    input = '<a href="/wiki/Special:Random">Random Page</a>'
    Sanitize.clean(input, { :elements => ['a'], :attributes => {'a' => ['href']}, :protocols => { 'a' => { 'href' => [:relative] }} }).must_equal(input)
  end

  it 'should output HTML when :output == :html' do
    input = 'foo<br/>bar<br>baz'
    Sanitize.clean(input, :elements => ['br'], :output => :html).must_equal('foo<br>bar<br>baz')
  end

  it 'should remove the contents of filtered nodes when :remove_contents == true' do
    Sanitize.clean('foo bar <div>baz<span>quux</span></div>', :remove_contents => true).must_equal('foo bar   ')
  end

  it 'should remove the contents of specified nodes when :remove_contents is an Array of element names as strings' do
    Sanitize.clean('foo bar <div>baz<span>quux</span><script>alert("hello!");</script></div>', :remove_contents => ['script', 'span']).must_equal('foo bar  baz ')
  end

  it 'should remove the contents of specified nodes when :remove_contents is an Array of element names as symbols' do
    Sanitize.clean('foo bar <div>baz<span>quux</span><script>alert("hello!");</script></div>', :remove_contents => [:script, :span]).must_equal('foo bar  baz ')
  end

  it 'should support encodings other than utf-8' do
    html = 'foo&nbsp;bar'
    Sanitize.clean(html).must_equal("foo\302\240bar")
    Sanitize.clean(html, :output_encoding => 'ASCII').must_equal("foo&#160;bar")
  end
end

describe 'Sanitize.clean' do
  it 'should not modify the input string' do
    input = '<b>foo</b>'
    Sanitize.clean(input)
    input.must_equal('<b>foo</b>')
  end

  it 'should return a new string' do
    input = '<b>foo</b>'
    Sanitize.clean(input).must_equal('foo')
  end
end

describe 'Sanitize.clean!' do
  it 'should modify the input string' do
    input = '<b>foo</b>'
    Sanitize.clean!(input)
    input.must_equal('foo')
  end

  it 'should return the string if it was modified' do
    input = '<b>foo</b>'
    Sanitize.clean!(input).must_equal('foo')
  end

  it 'should return nil if the string was not modified' do
    input = 'foo'
    Sanitize.clean!(input).must_equal(nil)
  end
end

describe 'Sanitize.clean_document' do
  before { @config = { :elements => ['html', 'p'] } }

  it 'should be idempotent' do
    input = '<!DOCTYPE html><html><p>foo</p></html>'
    first = Sanitize.clean_document(input, @config)
    second = Sanitize.clean_document(first, @config)
    second.must_equal first
    second.wont_be_nil
  end

  it 'should handle nil without raising' do
    Sanitize.clean_document(nil).must_equal nil
  end

  it 'should not modify the input string' do
    input = '<!DOCTYPE html><b>foo</b>'
    Sanitize.clean_document(input, @config)
    input.must_equal('<!DOCTYPE html><b>foo</b>')
  end

  it 'should return a new string' do
    input = '<!DOCTYPE html><b>foo</b>'
    Sanitize.clean_document(input, @config).must_equal("<!DOCTYPE html>\n<html>foo</html>\n")
  end
end

describe 'Sanitize.clean_document!' do
  before { @config = { :elements => ['html'] } }

  it 'should modify the input string' do
    input = '<!DOCTYPE html><html><body><b>foo</b></body></html>'
    Sanitize.clean_document!(input, @config)
    input.must_equal("<!DOCTYPE html>\n<html>foo</html>\n")
  end

  it 'should return the string if it was modified' do
    input = '<!DOCTYPE html><html><body><b>foo</b></body></html>'
    Sanitize.clean_document!(input, @config).must_equal("<!DOCTYPE html>\n<html>foo</html>\n")
  end

  it 'should return nil if the string was not modified' do
    input = "<!DOCTYPE html>\n<html></html>\n"
    Sanitize.clean_document!(input, @config).must_equal(nil)
  end
end

describe 'transformers' do
  # YouTube embed transformer.
  youtube = lambda do |env|
    node      = env[:node]
    node_name = env[:node_name]

    # Don't continue if this node is already whitelisted or is not an element.
    return if env[:is_whitelisted] || !node.element?

    # Don't continue unless the node is an iframe.
    return unless node_name == 'iframe'

    # Verify that the video URL is actually a valid YouTube video URL.
    return unless node['src'] =~ /\Ahttps?:\/\/(?:www\.)?youtube(?:-nocookie)?\.com\//

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

  it 'should receive a complete env Hash as input' do
    Sanitize.clean!('<SPAN>foo</SPAN>', :foo => :bar, :transformers => lambda {|env|
      return unless env[:node].element?

      env[:config][:foo].must_equal(:bar)
      env[:is_whitelisted].must_equal(false)
      env[:node].must_be_kind_of(Nokogiri::XML::Node)
      env[:node_name].must_equal('span')
      env[:node_whitelist].must_be_kind_of(Set)
      env[:node_whitelist].must_be_empty
    })
  end

  it 'should traverse all node types, including the fragment itself' do
    nodes = []

    Sanitize.clean!('<div>foo</div><!--bar--><script>cdata!</script>', :transformers => proc {|env|
      nodes << env[:node_name]
    })

    nodes.must_equal(%w[
      text div comment #cdata-section script #document-fragment
    ])
  end

  it 'should traverse in depth-first mode by default' do
    nodes = []

    Sanitize.clean!('<div><span>foo</span></div><p>bar</p>', :transformers => proc {|env|
      env[:traversal_mode].must_equal(:depth)
      nodes << env[:node_name] if env[:node].element?
    })

    nodes.must_equal(['span', 'div', 'p'])
  end

  it 'should traverse in breadth-first mode when using :transformers_breadth' do
    nodes = []

    Sanitize.clean!('<div><span>foo</span></div><p>bar</p>', :transformers_breadth => proc {|env|
      env[:traversal_mode].must_equal(:breadth)
      nodes << env[:node_name] if env[:node].element?
    })

    nodes.must_equal(['div', 'span', 'p'])
  end

  it 'should whitelist nodes in the node whitelist' do
    Sanitize.clean!('<div class="foo">foo</div><span>bar</span>', :transformers => [
      proc {|env|
        {:node_whitelist => [env[:node]]} if env[:node_name] == 'div'
      },

      proc {|env|
        env[:is_whitelisted].must_equal(false) unless env[:node_name] == 'div'
        env[:is_whitelisted].must_equal(true) if env[:node_name] == 'div'
        env[:node_whitelist].must_include(env[:node]) if env[:node_name] == 'div'
      }
    ]).must_equal('<div class="foo">foo</div>bar')
  end

  it 'should clear the node whitelist after each fragment' do
    called = false

    Sanitize.clean!('<div>foo</div>', :transformers => proc {|env|
      {:node_whitelist => [env[:node]]}
    })

    Sanitize.clean!('<div>foo</div>', :transformers =>  proc {|env|
      called = true
      env[:is_whitelisted].must_equal(false)
      env[:node_whitelist].must_be_empty
    })

    called.must_equal(true)
  end

  it 'should allow youtube video embeds via the youtube transformer' do
    input  = '<iframe width="420" height="315" src="http://www.youtube.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen bogus="bogus"><script>alert()</script></iframe>'
    output = Nokogiri::HTML::DocumentFragment.parse('<iframe width="420" height="315" src="http://www.youtube.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen>alert()</iframe>').to_html(:encoding => 'utf-8', :indent => 0)

    Sanitize.clean!(input, :transformers => youtube).must_equal(output)
  end

  it 'should allow https youtube video embeds via the youtube transformer' do
    input  = '<iframe width="420" height="315" src="https://www.youtube.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen bogus="bogus"><script>alert()</script></iframe>'
    output = Nokogiri::HTML::DocumentFragment.parse('<iframe width="420" height="315" src="https://www.youtube.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen>alert()</iframe>').to_html(:encoding => 'utf-8', :indent => 0)

    Sanitize.clean!(input, :transformers => youtube).must_equal(output)
  end

  it 'should allow privacy-enhanced youtube video embeds via the youtube transformer' do
    input  = '<iframe width="420" height="315" src="http://www.youtube-nocookie.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen bogus="bogus"><script>alert()</script></iframe>'
    output = Nokogiri::HTML::DocumentFragment.parse('<iframe width="420" height="315" src="http://www.youtube-nocookie.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen>alert()</iframe>').to_html(:encoding => 'utf-8', :indent => 0)

    Sanitize.clean!(input, :transformers => youtube).must_equal(output)
  end

  it 'should not allow non-youtube video embeds via the youtube transformer' do
    input  = '<iframe width="420" height="315" src="http://www.fake-youtube.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen></iframe>'
    output = ''

    Sanitize.clean!(input, :transformers => youtube).must_equal(output)
  end
end

describe 'bugs' do
  it 'should not have Nokogiri 1.4.2+ unterminated script/style element bug' do
    Sanitize.clean!('foo <script>bar').must_equal('foo bar')
    Sanitize.clean!('foo <style>bar').must_equal('foo bar')
  end
end
