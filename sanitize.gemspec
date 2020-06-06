# encoding: utf-8
require './lib/sanitize/version'

Gem::Specification.new do |s|
  s.name     = 'sanitize'
  s.summary  = 'Allowlist-based HTML and CSS sanitizer.'
  s.version  = Sanitize::VERSION
  s.authors  = ['Ryan Grove']
  s.email    = 'ryan@wonko.com'
  s.homepage = 'https://github.com/rgrove/sanitize/'
  s.licenses = ['MIT']

  s.description = 'Sanitize is an allowlist-based HTML and CSS sanitizer. It removes all HTML and/or CSS from a string except the elements, attributes, and properties you choose to allow.'

  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = Gem::Requirement.new('>= 2.1.0')
  s.required_rubygems_version = Gem::Requirement.new('>= 1.2.0')

  # Runtime dependencies.
  s.add_dependency('crass', '~> 1.0.2')
  s.add_dependency('nokogiri', '>= 1.8.0')
  s.add_dependency('nokogumbo', '~> 2.0')

  # Development dependencies.
  s.add_development_dependency('minitest', '~> 5.11.3')
  s.add_development_dependency('rake', '~> 12.3.1')

  s.require_paths = ['lib']

  s.files = [
    'HISTORY.md',
    'LICENSE',
    'README.md'
  ] + Dir.glob('lib/**/*.rb') + Dir.glob('test/**/*.rb')
end
