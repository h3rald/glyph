#!/usr/bin/env ruby
$: << File.expand_path(File.dirname(__FILE__) + '/lib')
require 'rubygems'
require 'rake/clean'
require 'spec/rake/spectask'
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
    s.add_development_dependency "rspec"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end

FileList['tasks/**/*.rake'].each { |t| load t}
