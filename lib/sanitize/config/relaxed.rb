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

class Sanitize
  module Config
    RELAXED = {
      :elements => %w[
        a abbr b bdo blockquote br caption cite code col colgroup dd del dfn dl
        dt em figcaption figure h1 h2 h3 h4 h5 h6 hgroup i img ins kbd li mark
        ol p pre q rp rt ruby s samp small strike strong sub sup table tbody td
        tfoot th thead time tr u ul var wbr
      ].freeze,

      :attributes => {
        :all         => ['dir', 'lang', 'title'].freeze,
        'a'          => ['href'].freeze,
        'blockquote' => ['cite'].freeze,
        'col'        => ['span', 'width'].freeze,
        'colgroup'   => ['span', 'width'].freeze,
        'del'        => ['cite', 'datetime'].freeze,
        'img'        => ['align', 'alt', 'height', 'src', 'width'].freeze,
        'ins'        => ['cite', 'datetime'].freeze,
        'ol'         => ['start', 'reversed', 'type'].freeze,
        'q'          => ['cite'].freeze,
        'table'      => ['summary', 'width'].freeze,
        'td'         => ['abbr', 'axis', 'colspan', 'rowspan', 'width'].freeze,
        'th'         => ['abbr', 'axis', 'colspan', 'rowspan', 'scope', 'width'].freeze,
        'time'       => ['datetime', 'pubdate'].freeze,
        'ul'         => ['type'].freeze
      }.freeze,

      :protocols => {
        'a'          => {'href' => ['ftp', 'http', 'https', 'mailto', :relative].freeze}.freeze,
        'blockquote' => {'cite' => ['http', 'https', :relative].freeze}.freeze,
        'del'        => {'cite' => ['http', 'https', :relative].freeze}.freeze,
        'img'        => {'src'  => ['http', 'https', :relative].freeze}.freeze,
        'ins'        => {'cite' => ['http', 'https', :relative].freeze}.freeze,
        'q'          => {'cite' => ['http', 'https', :relative].freeze}.freeze
      }.freeze
    }.freeze
  end
end
