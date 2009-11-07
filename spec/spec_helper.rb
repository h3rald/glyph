#!/usr/bin/env ruby
$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

require "stringio"
require "glyph"

Glyph.cfg :quiet => true

def create_project_dir
	@project = Glyph::SPEC_DIR/"test_project"
	@project.mkpath
end

def delete_project_dir
	@project.rmtree
end

def run_command(cmd)
	out = StringIO.new
	old_stdout = $stdout
	old_stderr = $stderr
	$stdout = out
	$stderr = out 
	GLI.run(cmd.split)
	$stdout = old_stdout
	$stderr = old_stderr
	out.string
end

