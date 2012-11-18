# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'catasta/version'

Gem::Specification.new do |s|
  s.name        = "catasta"
  s.version     = Catasta::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Max Aller"]
  s.email       = ["nanodeath@gmail.com"]
  s.homepage    = "http://github.com/nanodeath/Catasta"
  s.summary     = "Write-once, run everywhere templates"
  # s.description = "Bundler manages an application's dependencies through its entire life, across many machines, systematically and repeatably"
 
  s.required_rubygems_version = ">= 1.3.6"
 
  s.add_development_dependency "rspec", "~> 2.12.0"

  s.add_dependency "json", "~> 1.7.5"
  s.add_dependency "nokogiri", "~> 1.5.5"
  s.add_dependency "term-ansicolor", "~> 1.0.7"
  s.add_dependency "parslet"
 
  s.files        = Dir.glob("{bin,lib}/**/*")# + %w(LICENSE README.md ROADMAP.md CHANGELOG.md)
  s.executables  = ['catasta']
  s.require_path = 'lib'
end
