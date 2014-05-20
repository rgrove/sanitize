# encoding: utf-8

class Sanitize
  module Config
    RELAXED = freeze_config(
      :elements => BASIC[:elements] + %w[
        address article aside bdi bdo caption col colgroup data del div
        figcaption figure footer h1 h2 h3 h4 h5 h6 header hgroup hr img ins main
        nav rp rt ruby section span summary sup table tbody td tfoot th thead tr
        wbr
      ],

      :attributes => merge(BASIC[:attributes],
        :all       => %w[class dir id lang title translate],
        'a'        => %w[href hreflang rel],
        'col'      => %w[span width],
        'colgroup' => %w[span width],
        'data'     => %w[value],
        'del'      => %w[cite datetime],
        'img'      => %w[align alt height src width],
        'ins'      => %w[cite datetime],
        'li'       => %w[value],
        'ol'       => %w[reversed start type],
        'table'    => %w[sortable summary width],
        'td'       => %w[abbr axis colspan headers rowspan width],
        'th'       => %w[abbr axis colspan headers rowspan scope sorted width],
        'ul'       => %w[type]
      ),

      :protocols => merge(BASIC[:protocols],
        'del' => {'cite' => ['http', 'https', :relative]},
        'img' => {'src'  => ['http', 'https', :relative]},
        'ins' => {'cite' => ['http', 'https', :relative]}
      )
    )
  end
end
