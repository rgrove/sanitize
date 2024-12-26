# frozen_string_literal: true

require 'bundler'
require 'rake/clean'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

Rake::TestTask.new
task default: [:test]
task test: :set_rubyopts

task :set_rubyopts do
  ENV['RUBYOPT'] ||= ''
  ENV['RUBYOPT'] += ' -w'

  if RUBY_ENGINE == 'ruby'
    ENV['RUBYOPT'] += ' --enable-frozen-string-literal --debug=frozen-string-literal'
  end
end
