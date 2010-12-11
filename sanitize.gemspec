# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{sanitize}
  s.version = "2.0.0.dev.20101211"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ryan Grove"]
  s.date = %q{2010-12-11}
  s.email = %q{ryan@wonko.com}
  s.files = ["HISTORY", "LICENSE", "README.rdoc", "lib/sanitize/config/basic.rb", "lib/sanitize/config/relaxed.rb", "lib/sanitize/config/restricted.rb", "lib/sanitize/config.rb", "lib/sanitize/transformers/clean_cdata.rb", "lib/sanitize/transformers/clean_comment.rb", "lib/sanitize/transformers/clean_element.rb", "lib/sanitize/version.rb", "lib/sanitize.rb"]
  s.homepage = %q{https://github.com/rgrove/sanitize/}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.rubyforge_project = %q{riposte}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Whitelist-based HTML sanitizer.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, ["~> 1.4.4"])
      s.add_development_dependency(%q<minitest>, ["~> 2.0.0"])
      s.add_development_dependency(%q<rake>, ["~> 0.8.0"])
    else
      s.add_dependency(%q<nokogiri>, ["~> 1.4.4"])
      s.add_dependency(%q<minitest>, ["~> 2.0.0"])
      s.add_dependency(%q<rake>, ["~> 0.8.0"])
    end
  else
    s.add_dependency(%q<nokogiri>, ["~> 1.4.4"])
    s.add_dependency(%q<minitest>, ["~> 2.0.0"])
    s.add_dependency(%q<rake>, ["~> 0.8.0"])
  end
end
