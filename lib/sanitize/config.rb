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
    DEFAULT = {

      # Whether or not to allow HTML comments. Allowing comments is strongly
      # discouraged, since IE allows script execution within conditional
      # comments.
      :allow_comments => false,

      # HTML attributes to add to specific elements. By default, no attributes
      # are added.
      :add_attributes => {},

      # HTML attributes to allow in specific elements. By default, no attributes
      # are allowed. Use the symbol :data to indicate that arbitrary HTML5
      # data-* attributes should be allowed.
      :attributes => {},

      # HTML elements to allow. By default, no elements are allowed (which means
      # that all HTML will be stripped).
      :elements => [],

      # Output format. Supported formats are :html and :xhtml. Default is :html.
      :output => :html,

      # Character encoding to use for HTML output. Default is 'utf-8'.
      :output_encoding => 'utf-8',

      # URL handling protocols to allow in specific attributes. By default, no
      # protocols are allowed. Use :relative in place of a protocol if you want
      # to allow relative URLs sans protocol.
      :protocols => {},

      # If this is true, Sanitize will remove the contents of any filtered
      # elements in addition to the elements themselves. By default, Sanitize
      # leaves the safe parts of an element's contents behind when the element
      # is removed.
      #
      # If this is an Array of element names, then only the contents of the
      # specified elements (when filtered) will be removed, and the contents of
      # all other filtered elements will be left behind.
      :remove_contents => false,

      # Transformers allow you to filter or alter nodes using custom logic. See
      # README.rdoc for details and examples.
      :transformers => [],

      # By default, transformers perform depth-first traversal (deepest node
      # upward). This setting allows you to specify transformers that should
      # perform breadth-first traversal (top node downward).
      :transformers_breadth => [],

      # Elements which, when removed, should have their contents surrounded by
      # values specified with `before` and `after` keys to preserve readability.
      # For example, `foo<div>bar</div>baz` will become 'foo bar baz' when the
      # <div> is removed.
      :whitespace_elements => {
        'address'    => { :before => ' ', :after => ' ' },
        'article'    => { :before => ' ', :after => ' ' },
        'aside'      => { :before => ' ', :after => ' ' },
        'blockquote' => { :before => ' ', :after => ' ' },
        'br'         => { :before => ' ', :after => ' ' },
        'dd'         => { :before => ' ', :after => ' ' },
        'div'        => { :before => ' ', :after => ' ' },
        'dl'         => { :before => ' ', :after => ' ' },
        'dt'         => { :before => ' ', :after => ' ' },
        'footer'     => { :before => ' ', :after => ' ' },
        'h1'         => { :before => ' ', :after => ' ' },
        'h2'         => { :before => ' ', :after => ' ' },
        'h3'         => { :before => ' ', :after => ' ' },
        'h4'         => { :before => ' ', :after => ' ' },
        'h5'         => { :before => ' ', :after => ' ' },
        'h6'         => { :before => ' ', :after => ' ' },
        'header'     => { :before => ' ', :after => ' ' },
        'hgroup'     => { :before => ' ', :after => ' ' },
        'hr'         => { :before => ' ', :after => ' ' },
        'li'         => { :before => ' ', :after => ' ' },
        'nav'        => { :before => ' ', :after => ' ' },
        'ol'         => { :before => ' ', :after => ' ' },
        'p'          => { :before => ' ', :after => ' ' },
        'pre'        => { :before => ' ', :after => ' ' },
        'section'    => { :before => ' ', :after => ' ' },
        'ul'         => { :before => ' ', :after => ' ' }
      }
    }
  end
end
