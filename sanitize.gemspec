# encoding: utf-8
require './lib/sanitize/version'

Gem::Specification.new do |s|
  s.name     = 'sanitize'
  s.summary  = 'Whitelist-based HTML sanitizer.'
  s.version  = Sanitize::VERSION
  s.authors  = ['Ryan Grove']
  s.email    = 'ryan@wonko.com'
  s.homepage = 'https://github.com/rgrove/sanitize/'

  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = Gem::Requirement.new('>= 1.9.2')
  s.required_rubygems_version = Gem::Requirement.new('>= 1.2.0')

  # Runtime dependencies.
  s.add_dependency('nokogiri', '>= 1.4.4')

  # Development dependencies.
  s.add_development_dependency('minitest',  '~> 4.7')
  s.add_development_dependency('rake',      '~> 10.1')
  s.add_development_dependency('redcarpet', '~> 3.0.0')
  s.add_development_dependency('yard',      '~> 0.8.7')

  s.require_paths = ['lib']

  s.files = [
    'HISTORY.md',
    'LICENSE',
    'README.rdoc'
  ] + Dir.glob('lib/**/*.rb') + Dir.glob('test/**/*.rb')
end
