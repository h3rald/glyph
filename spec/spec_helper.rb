#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), "..", "lib", "glyph")

def setup_rake_app
	dir = File.dirname __FILE__
	@rake = Rake::Application.new
	Rake.application = @rake
	FileList["#{dir}/../tasks/**/*.rake"].each do |f|
		load f
	end	
end

def teardown_rake_app
	Rake.application = nil
end

def create_project_dir
	@project = Glyph::SPEC_DIR/"test_project"
	@project.mkpath
end

def delete_project_dir
	@project.rmtree
end

