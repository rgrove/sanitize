# encoding: utf-8
require_relative 'common'

describe 'Sanitize::Transformers::CleanElement' do
  make_my_diffs_pretty!
  parallelize_me!

  strings = {
    :basic => {
      :html       => '<b>Lo<!-- comment -->rem</b> <a href="pants" title="foo" style="text-decoration: underline;">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <style>.foo { color: #fff; }</style> <script>alert("hello world");</script>',

      :default    => 'Lorem ipsum dolor sit amet .foo { color: #fff; } alert("hello world");',
      :restricted => '<b>Lorem</b> ipsum <strong>dolor</strong> sit amet .foo { color: #fff; } alert("hello world");',
      :basic      => '<b>Lorem</b> <a href="pants" rel="nofollow">ipsum</a> <a href="http://foo.com/" rel="nofollow"><strong>dolor</strong></a> sit<br>amet .foo { color: #fff; } alert("hello world");',
      :relaxed    => '<b>Lorem</b> <a href="pants" title="foo" style="text-decoration: underline;">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br>amet <style>.foo { color: #fff; }</style> alert("hello world");'
    },

    :malformed => {
      :html       => 'Lo<!-- comment -->rem</b> <a href=pants title="foo>ipsum <a href="http://foo.com/"><strong>dolor</a></strong> sit<br/>amet <script>alert("hello world");',

      :default    => 'Lorem dolor sit amet alert("hello world");',
      :restricted => 'Lorem <strong>dolor</strong> sit amet alert("hello world");',
      :basic      => 'Lorem <a href="pants" rel="nofollow"><strong>dolor</strong></a> sit<br>amet alert("hello world");',
      :relaxed    => 'Lorem <a href="pants" title="foo&gt;ipsum &lt;a href="><strong>dolor</strong></a> sit<br>amet alert("hello world");',
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

      :default    => 'Lorem ipsum dolor sit amet &lt;script&gt;alert("hello world");',
      :restricted => '<b>Lorem</b> ipsum <strong>dolor</strong> sit amet &lt;script&gt;alert("hello world");',
      :basic      => '<b>Lorem</b> <a rel="nofollow">ipsum</a> <a href="http://foo.com/" rel="nofollow"><strong>dolor</strong></a> sit<br>amet &lt;script&gt;alert("hello world");',
      :relaxed    => '<b>Lorem</b> <a title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br>amet &lt;script&gt;alert("hello world");'
    }
  }

  protocols = {
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
      :relaxed    => '<img>'
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
      :relaxed    => '<img>'
    },

    'protocol whitespace' => {
      :html       => '<a href=" http://example.com/"></a>',
      :default    => '',
      :restricted => '',
      :basic      => '<a href="http://example.com/" rel="nofollow"></a>',
      :relaxed    => '<a href="http://example.com/"></a>'
    }
  }

  describe 'Basic config' do
    before do
      @s = Sanitize.new(Sanitize::Config::BASIC)
    end

    it 'should not choke on valueless attributes' do
      @s.clean('foo <a href>foo</a> bar')
        .must_equal 'foo <a href rel="nofollow">foo</a> bar'
    end
  end

  describe 'Custom configs' do
    it "should not allow relative URLs when relative URLs aren't whitelisted" do
      input = '<a href="/foo/bar">Link</a>'

      Sanitize.clean(input,
        :elements   => ['a'],
        :attributes => {'a' => ['href']},
        :protocols  => {'a' => {'href' => ['http']}}
      ).must_equal '<a>Link</a>'
    end
  end
end
