# Most of the code here (with slight tweaks) is from the Loofah project
# (http://github.com/flavorjones/loofah), and is included under the following
# license:
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

require 'hitimes'
require 'htmlfilter'
require 'loofah'
require_relative '../lib/sanitize'

class Measure
  def initialize
    clear
  end

  def clear
    @first_run = true
    @baseline  = nil
  end

  def measure(name, ntimes)
    if @first_run
      printf "  %-30s %7s  %8s  %5s\n", "", "total", "single", "rel"
      @first_run = false
    end

    timer = Hitimes::TimedMetric.new(name)
    error = nil

    begin
      timer.start
      ntimes.times {|j| yield }
    rescue => ex
      error = ex
    ensure
      timer.stop
    end

    if error
      printf "  %30s\n", timer.name + ' ERROR!'
    elsif @baseline
      printf "  %30s %7.3f (%8.6f) %5.2fx\n", timer.name, timer.sum, timer.sum / ntimes, timer.sum / @baseline
    else
      @baseline = timer.sum
      printf "  %30s %7.3f (%8.6f) %5s\n", timer.name, timer.sum, timer.sum / ntimes, "-"
    end

    timer.sum
  end
end

module TestSet
  def test_set(options = {})
    scale = options[:scale] || 1

    n = 1000 / scale
    puts "  Small HTML fragment (#{FRAGMENT_SMALL.length} bytes) x #{n}"
    bench(FRAGMENT_SMALL, n, true)
    puts

    n = 100 / scale
    puts "  Large HTML fragment (#{FRAGMENT_LARGE.length} bytes) x #{n}"
    bench(FRAGMENT_LARGE, n, true)
    puts

    n = 100 / scale
    puts "  Small HTML document (#{DOCUMENT_SMALL.length} bytes) x #{n}"
    bench(DOCUMENT_SMALL, n, false)
    puts

    n = 100 / scale
    puts "  Medium HTML document (#{DOCUMENT_MEDIUM.length} bytes) x #{n}"
    bench(DOCUMENT_MEDIUM, n, false)
    puts

    n = 5 / scale
    puts "  Huge HTML document (#{DOCUMENT_HUGE.length} bytes) x #{n}"
    bench(DOCUMENT_HUGE, n, false)
    puts
  end
end
