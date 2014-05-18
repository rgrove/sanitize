#!/usr/bin/env ruby

# To run benchmark.rb, you'll need the "hitimes" and "loofah" gems.
#
# The benchmarks and much of the code here are patterned after the benchmarks in
# the Loofah project (http://github.com/flavorjones/loofah), which has the
# following license:
#
# Copyright (c) 2009 Mike Dalessio, Bryan Helmkamp
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

DIR           = File.expand_path(File.dirname(__FILE__))
HTML_SLASHDOT = File.read("#{DIR}/html/test_slashdot.html")
HTML_BIG      = File.read("#{DIR}/html/test_big.html")
HTML_SMALL    = File.read("#{DIR}/html/test_small.html")
HTML_SNIPPET  = 'this is a tiny <em>snippet</em> of html'

require "#{DIR}/helpers"

class TestLoofah < Measure
  include TestSet

  def bench(html, times, is_fragment)
    clear

    @sanitize_config = Sanitize::Config::RELAXED.dup
    @sanitize_config[:allow_doctype] = true
    @sanitize_config[:elements] << 'html'

    @sanitize_config_prune = @sanitize_config.dup
    @sanitize_config_prune[:remove_contents] = true

    if is_fragment
      measure('Loofah :strip', times) do
        Loofah.scrub_fragment(html, :strip).to_s
      end

      measure('Loofah :prune', times) do
        Loofah.scrub_fragment(html, :prune).to_s
      end
    else
      measure('Loofah :strip', times) do
        Loofah.scrub_document(html, :strip).to_s
      end

      measure('Loofah :prune', times) do
        Loofah.scrub_document(html, :prune).to_s
      end
    end

    if is_fragment
      measure('Sanitize.fragment (strip)', times) do
        Sanitize.fragment(html, @sanitize_config)
      end

      measure('Sanitize.fragment (prune)', times) do
        Sanitize.fragment(html, @sanitize_config_prune)
      end
    else
      measure('Sanitize.document (strip)', times) do
        Sanitize.document(html, @sanitize_config)
      end

      measure('Sanitize.document (prune)', times) do
        Sanitize.document(html, @sanitize_config_prune)
      end
    end
  end
end

puts "Loofah version  : #{Loofah::VERSION}"
puts "Sanitize version: #{Sanitize::VERSION}"
puts "Nokogiri version: #{Nokogiri::VERSION_INFO.inspect}"
puts

benchmarks = [TestLoofah.new]

puts "These values are time measurements. Lower is faster!"
puts

puts "-- Rehearsal --"
benchmarks.each {|bm| bm.test_set(:scale => 10) }

puts "-- Benchmark --"
benchmarks.each {|bm| bm.test_set }
