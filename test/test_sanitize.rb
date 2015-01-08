# encoding: utf-8
require_relative 'common'

describe 'Sanitize' do
  describe 'instance methods' do
    before do
      @s = Sanitize.new
    end

    describe '#document' do
      before do
        @s = Sanitize.new(:elements => ['html'])
      end

      it 'should sanitize an HTML document' do
        @s.document('<!doctype html><html><b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script></html>')
          .must_equal "<html>Lorem ipsum dolor sit amet alert(\"hello world\");</html>\n"
      end

      it 'should not modify the input string' do
        input = '<!DOCTYPE html><b>foo</b>'
        @s.document(input)
        input.must_equal('<!DOCTYPE html><b>foo</b>')
      end
    end

    describe '#fragment' do
      it 'should sanitize an HTML fragment' do
        @s.fragment('<b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script>')
          .must_equal 'Lorem ipsum dolor sit amet alert("hello world");'
      end

      it 'should not modify the input string' do
        input = '<b>foo</b>'
        @s.fragment(input)
        input.must_equal '<b>foo</b>'
      end

      it 'should not choke on fragments containing <html> or <body>' do
        @s.fragment('<html><b>foo</b></html>').must_equal 'foo'
        @s.fragment('<body><b>foo</b></body>').must_equal 'foo'
        @s.fragment('<html><body><b>foo</b></body></html>').must_equal 'foo'
        @s.fragment('<!DOCTYPE html><html><body><b>foo</b></body></html>').must_equal 'foo'
      end
    end

    describe '#fragment_hash' do
      it 'should sanitize HTML fragments in a hash' do
        @s.fragment_hash({:body => '<b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script>', :extras => {}})
        .must_equal({:body => 'Lorem ipsum dolor sit amet alert("hello world");', :extras => {}})
      end

      it 'should not modify the input string' do
        input = {:body => '<b>foo</b>'}
        @s.fragment_hash(input)
        input.must_equal({:body => '<b>foo</b>'})
      end

      it 'should not choke on fragments containing <html> or <body>' do
        @s.fragment_hash({:body => '<html><b>foo</b></html>'}).must_equal({:body => 'foo'})
        @s.fragment_hash({ :body => '<body><b>foo</b></body>'}).must_equal({:body => 'foo'})
        @s.fragment_hash({ :body => '<html><body><b>foo</b></body></html>'}).must_equal({:body => 'foo'})
        @s.fragment_hash({ :body => '<!DOCTYPE html><html><body><b>foo</b></body></html>'}).must_equal({:body => 'foo'})
      end

    end

    describe '#node!' do
      it 'should sanitize a Nokogiri::XML::Node' do
        doc  = Nokogiri::HTML5.parse('<b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script>')
        frag = doc.fragment

        doc.xpath('/html/body/node()').each {|node| frag << node }

        @s.node!(frag)
        frag.to_html.must_equal 'Lorem ipsum dolor sit amet alert("hello world");'
      end

      describe "when the given node is a document and <html> isn't whitelisted" do
        it 'should raise a Sanitize::Error' do
          doc = Nokogiri::HTML5.parse('foo')
          proc { @s.node!(doc) }.must_raise Sanitize::Error
        end
      end
    end
  end

  describe 'class methods' do
    describe '.document' do
      it 'should call #document' do
        Sanitize.stub_instance(:document, proc {|html| html + ' called' }) do
          Sanitize.document('<html>foo</html>')
            .must_equal '<html>foo</html> called'
        end
      end
    end

    describe '.fragment' do
      it 'should call #fragment' do
        Sanitize.stub_instance(:fragment, proc {|html| html + ' called' }) do
          Sanitize.fragment('<b>foo</b>').must_equal '<b>foo</b> called'
        end
      end
    end

    describe '.node!' do
      it 'should call #node!' do
        Sanitize.stub_instance(:node!, proc {|input| input + ' called' }) do
          Sanitize.node!('not really a node').must_equal 'not really a node called'
        end
      end
    end
  end
end
