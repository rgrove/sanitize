# encoding: utf-8
require_relative 'common'

# Miscellaneous attempts to sneak maliciously crafted HTML past Sanitize. Many
# of these are courtesy of (or inspired by) the OWASP XSS Filter Evasion Cheat
# Sheet.
#
# https://www.owasp.org/index.php/XSS_Filter_Evasion_Cheat_Sheet

describe 'Malicious HTML' do
  make_my_diffs_pretty!
  parallelize_me!

  before do
    @s = Sanitize.new(Sanitize::Config::RELAXED)
  end

  # libxml2 >= 2.9.2 doesn't escape comments within some attributes, in an
  # attempt to preserve server-side includes. This can result in XSS since an
  # unescaped double quote can allow an attacker to inject a non-whitelisted
  # attribute. Sanitize works around this by implementing its own escaping for
  # affected attributes.
  #
  # The relevant libxml2 code is here:
  # <https://github.com/GNOME/libxml2/commit/960f0e275616cadc29671a218d7fb9b69eb35588>
  describe 'unsafe libxml2 server-side includes in attributes' do
    tag_configs = [
      {
        tag_name: 'a',
        escaped_attrs: %w[ action href src name ],
        unescaped_attrs: []
      },

      {
        tag_name: 'div',
        escaped_attrs: %w[ action href src ],
        unescaped_attrs: %w[ name ]
      }
    ]

    before do
      @s = Sanitize.new({
        elements: %w[ a div ],

        attributes: {
          all: %w[ action href src name ]
        }
      })
    end

    tag_configs.each do |tag_config|
      tag_name = tag_config[:tag_name]

      tag_config[:escaped_attrs].each do |attr_name|
        input = %[<#{tag_name} #{attr_name}='examp<!--" onmouseover=alert(1)>-->le.com'>foo</#{tag_name}>]

        it 'should escape unsafe characters in attributes' do
          @s.clean(input).must_equal(%[<#{tag_name} #{attr_name}="examp<!--%22%20onmouseover=alert(1)>-->le.com">foo</#{tag_name}>])
        end

        it 'should round-trip to the same output' do
          output = @s.clean(input)
          @s.clean(output).must_equal(output)
        end
      end

      tag_config[:unescaped_attrs].each do |attr_name|
        input = %[<#{tag_name} #{attr_name}='examp<!--" onmouseover=alert(1)>-->le.com'>foo</#{tag_name}>]

        it 'should not escape characters unnecessarily' do
          @s.clean(input).must_equal(input)
        end

        it 'should round-trip to the same output' do
          output = @s.clean(input)
          @s.clean(output).must_equal(output)
        end
      end
    end
  end
end
