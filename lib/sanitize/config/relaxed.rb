# encoding: utf-8

class Sanitize
  module Config
    RELAXED = {
      :elements => %w[
        a abbr address b bdi bdo blockquote br caption cite code col colgroup dd
        del dfn dl dt em figcaption figure h1 h2 h3 h4 h5 h6 hgroup hr i img ins
        kbd li mark ol p pre q rp rt ruby s samp small strike strong sub summary
        sup table tbody td tfoot th thead time tr u ul var wbr
      ],

      :attributes => {
        :all         => ['dir', 'lang', 'title'],
        'a'          => ['href'],
        'blockquote' => ['cite'],
        'col'        => ['span', 'width'],
        'colgroup'   => ['span', 'width'],
        'del'        => ['cite', 'datetime'],
        'img'        => ['align', 'alt', 'height', 'src', 'width'],
        'ins'        => ['cite', 'datetime'],
        'ol'         => ['start', 'reversed', 'type'],
        'q'          => ['cite'],
        'table'      => ['summary', 'width'],
        'td'         => ['abbr', 'axis', 'colspan', 'rowspan', 'width'],
        'th'         => ['abbr', 'axis', 'colspan', 'rowspan', 'scope', 'width'],
        'time'       => ['datetime', 'pubdate'],
        'ul'         => ['type']
      },

      :protocols => {
        'a'          => {'href' => ['ftp', 'http', 'https', 'mailto', :relative]},
        'blockquote' => {'cite' => ['http', 'https', :relative]},
        'del'        => {'cite' => ['http', 'https', :relative]},
        'img'        => {'src'  => ['http', 'https', :relative]},
        'ins'        => {'cite' => ['http', 'https', :relative]},
        'q'          => {'cite' => ['http', 'https', :relative]}
      }
    }
  end
end
