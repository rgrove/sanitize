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

$:.unshift("#{DIR}/../lib")

require 'rubygems'
require 'hitimes'
require 'loofah'
require 'sanitize'

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

    timer.start
    ntimes.times {|j| yield }
    timer.stop

    if @baseline
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

    n = 100 / scale
    puts "  Slashdot HTML doc (#{HTML_SLASHDOT.length} bytes) x #{n}"
    bench(HTML_SLASHDOT, n, false)
    puts

    n = 100 / scale
    puts "  Big HTML doc (#{HTML_BIG.length} bytes) x #{n}"
    bench(HTML_BIG, n, false)
    puts

    n = 1000 / scale
    puts "  Small HTML fragment (#{HTML_SMALL.length} bytes) x #{n}"
    bench HTML_SMALL, n, true
    puts

    n = 10_000 / scale
    puts "  Tiny HTML fragment (#{HTML_SNIPPET.length} bytes) x #{n}"
    bench(HTML_SNIPPET, n, true)
    puts
  end
end
