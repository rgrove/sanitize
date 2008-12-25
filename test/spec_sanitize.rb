#--
# Copyright (c) 2008 Ryan Grove <ryan@wonko.com>
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
require 'bacon'

require File.join(File.dirname(__FILE__), '../lib/sanitize')

strings = {
  :basic => {
    :html       => '<b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script>',
    :default    => 'Lorem ipsum dolor sitamet alert("hello world");',
    :restricted => '<b>Lorem</b> ipsum <strong>dolor</strong> sitamet alert("hello world");',
    :basic      => '<b>Lorem</b> <a rel="nofollow">ipsum</a> <a href="http://foo.com/" rel="nofollow"><strong>dolor</strong></a> sit<br />amet alert("hello world");',
    :relaxed    => '<b>Lorem</b> <a title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br />amet alert("hello world");'
  },

  :malformed => {
    :html       => 'Lo<!-- comment -->rem</b> <a href=pants title="foo>ipsum <a href="http://foo.com/"><strong>dolor</a></strong> sit<br/>amet <script>alert("hello world");',
    :default    => 'Lorem &lt;a href=pants title="foo&gt;ipsum dolor sitamet alert("hello world");',
    :restricted => 'Lorem &lt;a href=pants title="foo&gt;ipsum <strong>dolor</strong> sitamet alert("hello world");',
    :basic      => 'Lorem &lt;a href=pants title="foo&gt;ipsum <a href="http://foo.com/" rel="nofollow"><strong>dolor</strong></a> sit<br />amet alert("hello world");',
    :relaxed    => 'Lorem &lt;a href=pants title="foo&gt;ipsum <a href="http://foo.com/"><strong>dolor</strong></a> sit<br />amet alert("hello world");'
  },

  :malicious => {
    :html       => '<b>Lo<!-- comment -->rem</b> <a href="javascript:pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <<foo>script>alert("hello world");</script>',
    :default    => 'Lorem ipsum dolor sitamet &lt;script&gt;alert("hello world");',
    :restricted => '<b>Lorem</b> ipsum <strong>dolor</strong> sitamet &lt;script&gt;alert("hello world");',
    :basic      => '<b>Lorem</b> <a rel="nofollow">ipsum</a> <a href="http://foo.com/" rel="nofollow"><strong>dolor</strong></a> sit<br />amet &lt;script&gt;alert("hello world");',
    :relaxed    => '<b>Lorem</b> <a title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br />amet &lt;script&gt;alert("hello world");'
  }
}

describe 'Config::DEFAULT' do
  strings.each do |name, data|
    should "clean #{name} HTML" do
      Sanitize.clean(data[:html]).should.equal(data[:default])
    end
  end
end

describe 'Config::RESTRICTED' do
  strings.each do |name, data|
    should "clean #{name} HTML" do
      Sanitize.clean(data[:html], Sanitize::Config::RESTRICTED).should.equal(data[:restricted])
    end
  end
end

describe 'Config::BASIC' do
  strings.each do |name, data|
    should "clean #{name} HTML" do
      Sanitize.clean(data[:html], Sanitize::Config::BASIC).should.equal(data[:basic])
    end
  end
end

describe 'Config::RELAXED' do
  strings.each do |name, data|
    should "clean #{name} HTML" do
      Sanitize.clean(data[:html], Sanitize::Config::RELAXED).should.equal(data[:relaxed])
    end
  end
end

describe 'Sanitize.clean' do
  should 'not modify the input string' do
    input = '<b>foo</b>'
    Sanitize.clean(input)
    input.should.equal('<b>foo</b>')
  end

  should 'return the modified string' do
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

  should 'return the new string if it was modified' do
    input = '<b>foo</b>'
    Sanitize.clean!(input).should.equal('foo')
  end

  should 'return nil if the string was not modified' do
    input = 'foo'
    Sanitize.clean!(input).should.equal(nil)
  end
end
