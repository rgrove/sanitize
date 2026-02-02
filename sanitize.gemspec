# frozen_string_literal: true

require_relative "lib/sanitize/version"

Gem::Specification.new do |s|
  s.name = "sanitize"
  s.summary = "Allowlist-based HTML and CSS sanitizer."
  s.version = Sanitize::VERSION
  s.authors = ["Ryan Grove"]
  s.email = "ryan@wonko.com"
  s.homepage = "https://github.com/rgrove/sanitize/"
  s.licenses = ["MIT"]

  s.description = <<~DESCRIPTION
    Sanitize is an allowlist-based HTML and CSS sanitizer. It removes all HTML
    and/or CSS from a string except the elements, attributes, and properties you
    choose to allow.
  DESCRIPTION

  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = ">= 3.1.0"

  s.metadata = {
    "changelog_uri" => "https://github.com/rgrove/sanitize/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/github/rgrove/sanitize",
    "rubygems_mfa_required" => "true"
  }

  s.add_dependency("crass", "~> 1.0.2")
  s.add_dependency("nokogiri", ">= 1.16.8")

  s.require_paths = ["lib"]

  s.files = [
    "CHANGELOG.md",
    "LICENSE",
    "README.md"
  ] + Dir.glob("lib/**/*.rb")
end
