# encoding: utf-8

require 'bundler'
require 'rake/clean'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

Rake::TestTask.new

if ENV['TEST_RUBYOPT_FROZEN_STRING_LITERAL'] # see .travis.yml
  ENV['RUBYOPT'] = "--enable-frozen-string-literal --debug=frozen-string-literal"
  puts "enabling frozen string literals"
end

task :default => [:test]
