# encoding: utf-8

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
