#!/usr/bin/env ruby

# encoding: utf-8
#
# To run benchmark.rb, you'll need the "hitimes", "htmlfilter", and "loofah"
# gems.
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

DIR = File.expand_path(File.dirname(__FILE__))

DOCUMENT_HUGE   = File.read("#{DIR}/html/document-huge.html").encode('UTF-8', :invalid => :replace, :undef => :replace)
DOCUMENT_MEDIUM = File.read("#{DIR}/html/document-medium.html").encode('UTF-8', :invalid => :replace, :undef => :replace)
DOCUMENT_SMALL  = File.read("#{DIR}/html/document-small.html").encode('UTF-8', :invalid => :replace, :undef => :replace)

FRAGMENT_LARGE = File.read("#{DIR}/html/fragment-large.html").encode('UTF-8', :invalid => :replace, :undef => :replace)
FRAGMENT_SMALL = File.read("#{DIR}/html/fragment-small.html").encode('UTF-8', :invalid => :replace, :undef => :replace)

require "#{DIR}/helpers"

class Benchmark < Measure
  include TestSet

  def bench(html, times, is_fragment)
    clear

    sanitize_config = Sanitize::Config::RELAXED

    h = HTMLFilter.new(HTMLFilter::RELAXED)
    s = Sanitize.new(sanitize_config)

    # Sanitize
    if is_fragment
      measure('Sanitize#fragment', times) do
        s.fragment(html)
      end

      measure('Sanitize.fragment', times) do
        Sanitize.fragment(html, sanitize_config)
      end
    else
      measure('Sanitize#document', times) do
        s.document(html)
      end

      measure('Sanitize.document', times) do
        Sanitize.document(html, sanitize_config)
      end
    end

    # Loofah

    # I'm only testing Loofah's :strip mode here since it's analagous to
    # Sanitize's default behavior and there's very little difference between
    # the performance of the :strip and :prune modes anyway.

    if is_fragment
      measure('Loofah.scrub_fragment (strip)', times) do
        Loofah.scrub_fragment(html, :strip).to_s
      end
    else
      measure('Loofah.scrub_document (strip)', times) do
        Loofah.scrub_document(html, :strip).to_s
      end
    end

    # HTMLFilter
    measure('HTMLFilter#filter', times) do
      h.filter(html)
    end
  end
end

puts "Ruby version      : #{RUBY_VERSION}"
puts "Sanitize version  : #{Sanitize::VERSION}"
puts "Loofah version    : #{Loofah::VERSION}"
puts "HTMLFilter version: #{HTMLFilter::VERSION}"
puts
puts "Nokogiri version: #{Nokogiri::VERSION_INFO.inspect}"
puts

benchmarks = [Benchmark.new]

puts "These values are time measurements. Lower is faster!"
puts

# puts "-- Rehearsal --"
# benchmarks.each {|bm| bm.test_set(:scale => 10) }

puts "-- Benchmark --"
benchmarks.each {|bm| bm.test_set }
