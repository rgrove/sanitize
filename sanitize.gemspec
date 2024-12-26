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
  s.required_ruby_version = Gem::Requirement.new('>= 2.5.0')
  s.required_rubygems_version = Gem::Requirement.new('>= 1.2.0')

  s.metadata = {
    "changelog_uri"     => "https://github.com/rgrove/sanitize/blob/main/HISTORY.md",
    "documentation_uri" => "https://rubydoc.info/github/rgrove/sanitize"
  }

  # Runtime dependencies.
  s.add_dependency('crass', '~> 1.0.2')
  s.add_dependency('nokogiri', '>= 1.16.8')

  # Development dependencies.
  s.add_development_dependency('minitest', '~> 5.15') # needs to float to support ruby 2.5 and 3.4
  s.add_development_dependency('rake', '~> 13.0.6')

  s.require_paths = ['lib']

  s.files = [
    'HISTORY.md',
    'LICENSE',
    'README.md'
  ] + Dir.glob('lib/**/*.rb') + Dir.glob('test/**/*.rb')
end
