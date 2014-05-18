# encoding: utf-8
require_relative 'common'

describe 'Parser' do
  make_my_diffs_pretty!
  parallelize_me!

  it 'should translate valid entities into characters' do
    Sanitize.fragment("&apos;&eacute;&amp;").must_equal("'é&amp;")
  end

  it 'should translate orphaned ampersands into entities' do
    Sanitize.fragment('at&t').must_equal('at&amp;t')
  end

  it 'should not add newlines after tags when serializing a fragment' do
    Sanitize.fragment("<div>foo\n\n<p>bar</p><div>\nbaz</div></div><div>quux</div>", :elements => ['div', 'p'])
      .must_equal "<div>foo\n\n<p>bar</p><div>\nbaz</div></div><div>quux</div>"
  end

  it 'should not have the Nokogiri 1.4.2+ unterminated script/style element bug' do
    Sanitize.fragment('foo <script>bar').must_equal('foo bar')
    Sanitize.fragment('foo <style>bar').must_equal('foo bar')
  end
end
