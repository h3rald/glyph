#!/usr/bin/env ruby
$: << File.expand_path(File.dirname(__FILE__) + '/lib')
require 'rubygems'
require 'rake/clean'
require 'glyph'

task :default => :spec

begin
	require 'yard'
	YARD::Rake::YardocTask.new(:yardoc) do |t|
		t.files   = ['lib/**/*.rb', 'README.textile', 'lib/*.rb'] 
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
		s.add_dependency 'gli', '>= 0.3.1'
		s.add_dependency 'extlib', '>= 0.9.12'
		s.add_dependency 'treetop', '>= 0.4.3'
		s.add_dependency 'rake', '>= 0.8.7'
		s.add_development_dependency 'rspec'
		s.add_development_dependency 'yard'
		s.add_development_dependency 'jeweler'
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
