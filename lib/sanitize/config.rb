#--
# Copyright (c) 2010 Ryan Grove <ryan@wonko.com>
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
      # are allowed.
      :attributes => {},

      # HTML elements to allow. By default, no elements are allowed (which means
      # that all HTML will be stripped).
      :elements => [],

      # Output format. Supported formats are :html and :xhtml (which is the
      # default).
      :output => :xhtml,

      # URL handling protocols to allow in specific attributes. By default, no
      # protocols are allowed. Use :relative in place of a protocol if you want
      # to allow relative URLs sans protocol.
      :protocols => {},

      :transformers => []
    }
  end
end
