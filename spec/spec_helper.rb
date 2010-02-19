#!/usr/bin/env ruby
$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

require "stringio"

module Glyph; end

begin
	unless Glyph.const_defined? :TEST_MODE then
		Glyph::TEST_MODE = true
	end
rescue Exception => e
end

require "glyph"

Glyph.config_override :quiet, true

def create_project_dir
	Glyph::PROJECT.mkpath
end

def create_project
	enable_all_tasks
	create_project_dir
	Glyph.run! 'project:create', Glyph::PROJECT.to_s
	file_copy Glyph::SPEC_DIR/'files/container.textile', Glyph::PROJECT/'text/container.textile'
	(Glyph::PROJECT/'text/a/b/c').mkpath
	file_copy Glyph::SPEC_DIR/'files/included.textile', Glyph::PROJECT/'text/a//b/c/included.textile'
	file_copy Glyph::SPEC_DIR/'files/markdown.markdown', Glyph::PROJECT/'text/a//b/c/markdown.markdown'
	file_copy Glyph::SPEC_DIR/'files/document.glyph', Glyph::PROJECT/'document.glyph'
	file_copy Glyph::SPEC_DIR/'files/test.sass', Glyph::PROJECT/'styles/test.sass'
	file_copy Glyph::SPEC_DIR/'files/ligature.jpg', Glyph::PROJECT/'images/ligature.jpg'
end

def enable_all_tasks
	Rake::Task.tasks.each {|t| t.reenable }
end

def delete_project_dir
	FileUtils.rm_rf Glyph::PROJECT.to_s
end

def delete_project 
	delete_project_dir
	Glyph::SNIPPETS.clear
	Glyph::MACROS.clear
	Glyph.config_override 'document.source', 'document.glyph'
	Glyph.instance_eval { remove_const :DOCUMENT rescue nil }
end

def run_command(cmd)
	out = StringIO.new
	old_stdout = $stdout
	old_stderr = $stderr
	$stdout = out
	$stderr = out 
	Glyph.config_override :quiet, false
	GLI.run(cmd)
	Glyph.config_override :quiet, true
	$stdout = old_stdout
	$stderr = old_stderr
	out.string
end

def run_command_successfully(cmd)
	run_command(cmd).match(/error/) == nil
end

def define_em_macro
	Glyph.macro :em do
		%{<em>#{@value}</em>}
	end
end

def define_ref_macro
	Glyph.macro :ref do
		%{<a href="#{@params[0]}">#{@params[1]}</a>}
	end
end

def interpret(text)
	@p = Glyph::Interpreter.new(text)
end

def create_tree(text)
	GlyphLanguageParser.new.parse text 
end

def create_doc(tree)
	Glyph::Document.new tree, {} 
end
