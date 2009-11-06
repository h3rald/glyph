require 'rubygems'
require 'rake/clean'
require 'rake/gempackagetask'
require 'spec/rake/spectask'
require 'lib/glyph'

gemspec = eval(File.read('glyph.gemspec'))

Rake::GemPackageTask.new(gemspec) { |pkg| }

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end

task :default => :spec

FileList['tasks/*/*.rake'].each { |rakefile| load rakefile}
