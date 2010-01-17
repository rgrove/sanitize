# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{sanitize}
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ryan Grove"]
  s.date = %q{2010-01-17}
  s.email = %q{ryan@wonko.com}
  s.files = ["HISTORY", "LICENSE", "README.rdoc", "lib/sanitize/config/basic.rb", "lib/sanitize/config/relaxed.rb", "lib/sanitize/config/restricted.rb", "lib/sanitize/config.rb", "lib/sanitize/version.rb", "lib/sanitize.rb"]
  s.homepage = %q{http://github.com/rgrove/sanitize/}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
  s.rubyforge_project = %q{riposte}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Whitelist-based HTML sanitizer.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, ["~> 1.4.1"])
      s.add_development_dependency(%q<bacon>, ["~> 1.1.0"])
      s.add_development_dependency(%q<rake>, ["~> 0.8.0"])
    else
      s.add_dependency(%q<nokogiri>, ["~> 1.4.1"])
      s.add_dependency(%q<bacon>, ["~> 1.1.0"])
      s.add_dependency(%q<rake>, ["~> 0.8.0"])
    end
  else
    s.add_dependency(%q<nokogiri>, ["~> 1.4.1"])
    s.add_dependency(%q<bacon>, ["~> 1.1.0"])
    s.add_dependency(%q<rake>, ["~> 0.8.0"])
  end
end
