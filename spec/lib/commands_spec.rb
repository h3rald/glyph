#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")
require 'glyph/commands'

describe "glyph" do

	before do
		create_project_dir
	end

	after do
		reset_quiet
		delete_project
	end

	it "[init] should create a project in the current directory" do
		delete_project
		Glyph.enable "project:create"
		Dir.chdir Glyph::PROJECT.to_s
		run_command_successfully(['init']).should == true
	end

	it "[config] should read configuration settings" do
		create_project
		run_command_successfully(["config", "-g"]).should == false
		run_command(["config", "filters.target"]).match(/html/m).should_not == nil
	end

	it "[config] should write configuration settings" do
		create_project
		run_command_successfully(["config", "test_setting", true]).should == true
		Glyph::CONFIG.get(:test_setting).should == true
		Glyph::PROJECT_CONFIG.read
		Glyph::PROJECT_CONFIG.get('test_setting').should == true
		Glyph::GLOBAL_CONFIG.read
		Glyph::GLOBAL_CONFIG.get('test_setting').should_not == true
		run_command_successfully(["config", "-g", "another.test", "something else"]).should == true
		(Glyph::SPEC_DIR/'.glyphrc').exist?.should == true
		Glyph::CONFIG.get("another.test").should == "something else"
		Glyph::PROJECT_CONFIG.read
		Glyph::PROJECT_CONFIG.get('another.test').should_not == "something else"
		Glyph::GLOBAL_CONFIG.read
		Glyph::GLOBAL_CONFIG.get('another.test').should == "something else"
		run_command_successfully(["config", "-g", "yet.another.test", "something else", "extra argument"]).should == false
		(Glyph::SPEC_DIR/'.glyphrc').unlink
	end

	it "[config] should not overwrite system settings" do
		create_project
		Glyph['system.test_setting'] = false
		run_command(["config", "system.test_setting", true]).match(/warning.+\(system use only\)/m).should_not == nil
		Glyph['system.test_setting'].should == false
	end

	it "[add] should create a new text file" do
		create_project
		run_command_successfully(["add", "test.textile"]).should == true
		(Glyph::PROJECT/'text/test.textile').exist?.should == true
	end

	it "[compile] should compile the project" do
		create_project
		run_command(["compile"]).match(/test_project\.html/m).should_not == nil
		(Glyph::PROJECT/'output/html/test_project.html').exist?.should == true
	end

	it "[compile] should support a custom source file" do
		create_project
		file_copy Glyph::PROJECT/'document.glyph', Glyph::PROJECT/'custom.glyph'
		run_command(["compile", "-s", "custom.glyph"]).match(/custom\.glyph/m).should_not == nil
		(Glyph::PROJECT/'output/html/test_project.html').exist?.should == true
	end

	it "[compile] should not continue execution in case of macro errors" do
		create_project
		text = %{
			=>[#invalid1]
			=>[#invalid2]
			=>[#valid]
			&[test]
			&[invalid3]
			#[valid|Valid bookmark]
		}
		file_write Glyph::PROJECT/'document.glyph', text
		res = run_command(["compile"])
		res.match(/Bookmark 'invalid1' does not exist/).should_not == nil
		res.match(/Bookmark 'invalid2' does not exist/).should_not == nil
		res.match(/Bookmark 'valid' does not exist/).should == nil
		res.match(/Snippet 'invalid3' does not exist/).should_not == nil
	end

	it "[compile] should regenerate output with auto switch set" do
		require 'timeout'
		create_project
		res = ''

		compile_thread = Thread.new do
			res = run_command(['-d', 'compile', '--auto'])
		end

		output_file = (Glyph::PROJECT/'output/html/test_project.html')
		Timeout.timeout(5, StandardError) do loop do
			break if output_file.file?
			sleep 1
		end end
		output = file_load output_file
		output_file.unlink

		text_file = (Glyph::PROJECT/'text/container.textile')
		text_file.unlink

		file_write text_file, "section[\nheader[Container section]\nThis is another test.\n]\n"

		Timeout.timeout(5, StandardError) do 
			loop do
				break if output_file.file?
				sleep 1
			end 
		end
		compile_thread.raise Interrupt
		compile_thread.join

		output2 = file_load output_file
		output.should_not == output2
		output2.match(/<p>This is another test.<\/p>/).should_not == nil

		res.match(/Auto-regeneration enabled/).should_not == nil
		res.match(/Regeneration started: 1 files changed/).should_not == nil
		reset_quiet
	end

	it "[compile] should not compile the project in case of an unknown output format" do
		reset_quiet
		run_command_successfully(["compile", "-f", "wrong"]).should == false
	end

	it "[compile] should compile a single source file" do
		reset_quiet
		Dir.chdir Glyph::PROJECT
		file_copy "#{Glyph::PROJECT}/../files/article.glyph", "#{Glyph::PROJECT}/article.glyph"
		file_copy "#{Glyph::PROJECT}/../files/ligature.jpg", "#{Glyph::PROJECT}/ligature.jpg"
		run_command_successfully(["compile", "article.glyph"]).should == true
		Pathname.new('article.html').exist?.should == true
		file_load('article.html').gsub(/\t|\n/, '').should == %{
			<div class="section">
				Test -- Test Snippet
			</div>
		}.gsub(/\t|\n/, '')
		Glyph.enable 'generate:html'
		(Glyph::PROJECT/'article.html').unlink
		Glyph['document.output'] = 'pdf'
		run_command_successfully(["compile", "article.glyph"]).should == true
		(Glyph::PROJECT/'article.html').exist?.should == true
		(Glyph::PROJECT/'article.pdf').exist?.should == true
		Glyph.lite_mode = false
	end	

	it "[compile] should compile a single source file to a custom destination" do 
		reset_quiet
		Dir.chdir Glyph::PROJECT
		file_copy "#{Glyph::PROJECT}/../files/article.glyph", "#{Glyph::PROJECT}/article.glyph"
		file_copy "#{Glyph::PROJECT}/../files/ligature.jpg", "#{Glyph::PROJECT}/ligature.jpg"
		run_command_successfully(["compile", "article.glyph", "out/article.htm"]).should == true
		Glyph.lite_mode = false
		Pathname.new('out/article.htm').exist?.should == true 
	end

	it "[compile] should finalize the document in case of errors in included files" do
		create_project
		file_write Glyph::PROJECT/'document.glyph', "section[@title[Test]\ninclude[errors.glyph]\ninclude[syntax_error.glyph]]"
		file_write Glyph::PROJECT/'text/errors.glyph', "not[a|b]"
		file_write Glyph::PROJECT/'text/syntax_error.glyph', "$[a"
		err = "Document cannot be finalized due to previous errors"
		res = run_command(["compile"])
		out = file_load Glyph::PROJECT/'output/html/test_project.html'
		out.should == %{<div class="section">
<h2 id="h_1">Test</h2>
<span class="todo"><span class="todo-pre"><strong>TODO:</strong> </span>Correct errors in file 'errors.glyph'</span>
<span class="todo"><span class="todo-pre"><strong>TODO:</strong> </span>Correct errors in file 'syntax_error.glyph'</span>

</div>}
		res.match("error: #{err}").should == nil
	end

	it "[outline] should display the document outline" do
		create_project
		start = %{Loading snippets...
Loading macros...
Parsing 'document.glyph'...
Processing...
Post-processing...
=====================================
test_project - Outline
=====================================}
		c_file = "----- file: container.textile"
		i_file = "----- file: included.textile"
		m_file = "----- file: markdown.markdown"
		c_title = "Container section "
		i_title = "Test Section "
		m_title = "Markdown "
		c_id = "[#h_1]"
		i_id = "[#h_2]"
		m_id = "[#md]"
		run_command(["outline"]).should == %{#{start}
  #{c_title}
    #{i_title}
  #{m_title}
}
		reset_quiet
		run_command(["outline", "-li"]).should == %{#{start}
  h2: #{c_id}
    h3: #{i_id}
  h2: #{m_id}
}
		reset_quiet
		run_command(["outline", "-lift"]).should == %{#{start}
#{c_file}
  h2: #{c_title}#{c_id}
#{i_file}
    h3: #{i_title}#{i_id}
#{m_file}
  h2: #{m_title}#{m_id}
}
	end

end
