#!/usr/bin/env ruby
$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

require "stringio"
require "glyph"

Glyph.config_override :quiet, true
begin
	unless Glyph.const_defined? :TEST_PROJECT then
		Glyph::TEST_PROJECT = Glyph::SPEC_DIR/"test_project"
	end
rescue Exception => e
end

def create_project_dir
	@project = Glyph::TEST_PROJECT
	@project.mkpath
end

def create_project
	Glyph.enable "project:create"
	create_project_dir
	Glyph::APP['project:create'].invoke @project
end

def delete_project_dir
	@project.rmtree
end

alias delete_project delete_project_dir

def run_command(cmd)
	out = StringIO.new
	old_stdout = $stdout
	old_stderr = $stderr
	$stdout = out
	$stderr = out 
	GLI.run(cmd)
	$stdout = old_stdout
	$stderr = old_stderr
	out.string
end

