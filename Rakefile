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

require 'rubygems'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'

require './lib/sanitize/version'

gemspec = Gem::Specification.new do |s|
  s.rubyforge_project = 'riposte'

  s.name     = 'sanitize'
  s.summary  = 'Whitelist-based HTML sanitizer.'
  s.version  = Sanitize::VERSION
  s.author   = 'Ryan Grove'
  s.email    = 'ryan@wonko.com'
  s.homepage = 'http://github.com/rgrove/sanitize/'
  s.platform = Gem::Platform::RUBY

  s.require_path          = 'lib'
  s.required_ruby_version = '>= 1.8.6'

  # Runtime dependencies.
  s.add_dependency('nokogiri', '~> 1.4.1')

  # Development dependencies.
  s.add_development_dependency('bacon', '~> 1.1.0')
  s.add_development_dependency('rake',  '~> 0.8.0')

  s.files = FileList[
    'HISTORY',
    'LICENSE',
    'README.rdoc',
    'lib/**/*.rb'
  ].to_a
end

Rake::GemPackageTask.new(gemspec) do |p|
  p.need_tar = false
  p.need_zip = false
end

Rake::RDocTask.new do |rd|
  rd.main     = 'README.rdoc'
  rd.title    = 'Sanitize Documentation'
  rd.rdoc_dir = 'doc'

  rd.rdoc_files.include('README.rdoc', 'lib/**/*.rb')

  rd.options << '--line-numbers' << '--inline-source'
end

task :default => [:test]

desc 'generate an updated gemspec'
task :gemspec do
  filename = File.join(File.dirname(__FILE__), "#{gemspec.name}.gemspec")
  File.open(filename, 'w') {|f| f << gemspec.to_ruby }
  puts "Created gemspec: #{filename}"
end

desc 'install Sanitize'
task :install => :gem do
  sh "gem install pkg/sanitize-#{Sanitize::VERSION}.gem"
end

task :test do
  sh 'bacon -a'
end
