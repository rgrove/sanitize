Gem::Specification.new do |s|
  s.name     = 'sanitize'
  s.summary  = 'Whitelist-based HTML sanitizer.'
  s.version  = '1.0.6.2'
  s.author   = 'Ryan Grove'
  s.email    = 'ryan@wonko.com'
  s.homepage = 'http://github.com/rgrove/sanitize/'
  s.platform = Gem::Platform::RUBY

  s.require_path          = 'lib'
  s.required_ruby_version = '>= 1.8.6'

  s.add_dependency('hpricot', '~> 0.8.1')

  s.files = [
    'HISTORY',
    'LICENSE',
    'README.rdoc',
    'lib/sanitize.rb',
    'lib/sanitize/config.rb',
    'lib/sanitize/config/basic.rb',
    'lib/sanitize/config/relaxed.rb',
    'lib/sanitize/config/restricted.rb'
  ]
end
