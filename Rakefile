#!/usr/bin/env ruby
# encoding: utf-8

lib = File.expand_path(File.dirname(__FILE__) + '/lib')
$: << lib
require 'rubygems'
require 'rake/clean'
require "#{lib}/glyph.rb"

task :default => :spec

# Jeweler
begin
	require 'jeweler'
	Jeweler::Tasks.new do |s|
		s.name = "glyph"
		s.summary = "Glyph -- A Ruby-powered Document Authoring Framework"
		s.description = "Glyph is a framework for structured document authoring."
		s.email = "h3rald@h3rald.com"
		s.homepage = "http://www.h3rald.com/glyph/"
		s.authors = ["Fabio Cevasco"]
		s.version = Glyph::VERSION
		s.files.exclude 'book/output/**/*'
		s.add_dependency 'gli', '>= 1.2.6' # Command line interface
		s.add_dependency 'extlib', '>= 0.9.15' # Extension methods
		s.add_dependency 'rake', '>= 0.8.7' # Glyph rasks
		s.add_development_dependency 'rspec', '>= 2.5.1' # Test suite
		s.add_development_dependency 'yard', '>= 0.6.7' # Documentation suite
		s.add_development_dependency 'jeweler', '1.5.2' # Gem management
		s.add_development_dependency 'directory_watcher', ">= 1.4.0" # Auto-regeneration
		s.add_development_dependency 'haml', ">= 3.0.25" # Sass filter
		s.add_development_dependency 'RedCloth', ">= 4.2.7" # Textile filter
		s.add_development_dependency 'bluecloth', ">= 2.1.0" # Markdown filter
		s.add_development_dependency 'coderay', ">= 0.9.7" # Syntax Highlighting
	end
	Jeweler::GemcutterTasks.new
rescue LoadError
	puts "Jeweler is not available. Install it with: gem install jeweler"
end

# RSpec
begin
	require "rspec/core/rake_task"
	RSpec::Core::RakeTask.new(:spec) do |t|
		t.pattern = 'spec/**/*_spec.rb'
		t.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
	end
	RSpec::Core::RakeTask.new(:test) do |t|
		args = ARGV.reverse
		args.pop
		t.pattern = args.join " "
		t.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
	end
rescue LoadError
	puts "RSpec is not available. Install it with: gem install rspec"
end

# Yard
begin
	require 'yard'
	YARD::Rake::YardocTask.new(:yardoc) do |t|
		t.files   = ['lib/**/*.rb', './README.textile', 'lib/*.rb']
		t.options = ['--no-private']
	end
rescue LoadError
	puts "YARD is not available. Install it with: gem install yard"
end

FileList['tasks/**/*.rake'].each { |t| load t}
