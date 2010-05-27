#!/usr/bin/env ruby
$: << File.expand_path(File.dirname(__FILE__) + '/lib')
require 'rubygems'
require 'rake/clean'
require 'glyph'

task :default => :spec

begin
	require 'yard'
	YARD::Rake::YardocTask.new(:yardoc) do |t|
		t.files   = ['lib/**/*.rb', './README.textile', 'lib/*.rb'] 
		t.options = ['--no-private']
	end
rescue LoadError
	task :yardoc do
		abort "YARD is not available. Install it with: gem install yard"
	end
end

begin
	require 'jeweler'
	Jeweler::Tasks.new do |s|
		s.name = "glyph"
		s.summary = "Glyph -- A Ruby-powered Document Authoring Framework"
		s.description = "Glyph is a framework for structured document authoring."
		s.email = "h3rald@h3rald.com"
		s.homepage = "http://www.h3rald.com/glyph/"
		s.authors = ["Fabio Cevasco"]
		s.files.include "styles/**/*"
		s.files.include "book/**/*"
		s.add_dependency 'gli', '>= 0.3.1' # Command line interface
		s.add_dependency 'extlib', '>= 0.9.12' # Extension methods
		s.add_dependency 'rake', '>= 0.8.7' # Glyph rasks
		s.add_development_dependency 'rspec', '>= 1.1.11' # Test suite
		s.add_development_dependency 'yard', '>= 1.5.4' # Documentation suite
		s.add_development_dependency 'jeweler', '1.4.0' # Gem management
		s.add_development_dependency 'directory_watcher', ">= 1.3.2" # Auto-regeneration
		s.add_development_dependency 'haml', ">= 2.2.3" # Sass filter
		s.add_development_dependency 'RedCloth', ">= 4.2.3" # Textile filter
		s.add_development_dependency 'bluecloth', ">= 2.0.7" # Markdown filter
		s.add_development_dependency 'coderay', ">= 0.9.3" # Syntax Highlighting
	end
	Jeweler::GemcutterTasks.new
rescue LoadError
	puts "Jeweler is not available. Install it with: gem install jeweler"
end

begin
	require 'spec/rake/spectask'
	Spec::Rake::SpecTask.new('spec') do |t|
		t.spec_files = FileList['spec/**/*_spec.rb']
		t.spec_opts = ["--color"]
	end
rescue LoadError
	puts "RSpec is not available. Install it with: gem install rspec"
end

FileList['tasks/**/*.rake'].each { |t| load t}
