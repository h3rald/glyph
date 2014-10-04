#!/usr/bin/env ruby
# encoding: utf-8


require File.join(File.dirname(__FILE__), "..", "spec_helper")

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
		expect(run_command_successfully(['init'])).to eq(true)
	end

	it "[config] should read configuration settings" do
		create_project
		expect(run_command_with_status(["config", "-g"])).to eq(-10)
		expect(run_command(["config", "document.output"]).match(/html/m)).not_to eq(nil)
	end

	it "[config] should write configuration settings" do
		create_project
		expect(run_command_successfully(["config", "test_setting", "true"])).to eq(true)
		expect(Glyph::CONFIG.get(:test_setting)).to eq(true)
		Glyph::PROJECT_CONFIG.read
		expect(Glyph::PROJECT_CONFIG.get('test_setting')).to eq(true)
		Glyph::GLOBAL_CONFIG.read
		expect(Glyph::GLOBAL_CONFIG.get('test_setting')).not_to eq(true)
		expect(run_command_successfully(["config", "-g", "another.test", "something else"])).to eq(true)
		expect((Glyph::SPEC_DIR/'.glyphrc').exist?).to eq(true)
		expect(Glyph::CONFIG.get("another.test")).to eq("something else")
		Glyph::PROJECT_CONFIG.read
		expect(Glyph::PROJECT_CONFIG.get('another.test')).not_to eq("something else")
		Glyph::GLOBAL_CONFIG.read
		expect(Glyph::GLOBAL_CONFIG.get('another.test')).to eq("something else")
		(Glyph::SPEC_DIR/'.glyphrc').unlink
	end

	it "[config] should not overwrite system settings" do
		create_project
		Glyph['system.test_setting'] = false
		expect(run_command(["config", "system.test_setting", "true"]).match(/warning.+\(system use only\)/m)).not_to eq(nil)
		expect(Glyph['system.test_setting']).to eq(false)
	end

	it "[add] should create a new text file" do
		create_project
		expect(run_command_successfully(["add", "test.textile"])).to eq(true)
		expect((Glyph::PROJECT/'text/test.textile').exist?).to eq(true)
	end

	it "[compile] should compile the project" do
		create_project
		expect(run_command(["compile"]).match(/test_project\.html/m)).not_to eq(nil)
		expect((Glyph::PROJECT/'output/html/test_project.html').exist?).to eq(true)
	end

	it "[compile] should support a custom source file" do
		create_project
		file_copy Glyph::PROJECT/'document.glyph', Glyph::PROJECT/'custom.glyph'
		expect(run_command(["-d", "compile", "-s", "custom.glyph"]).match(/custom\.glyph/m)).not_to eq(nil)
		expect((Glyph::PROJECT/'output/html/test_project.html').exist?).to eq(true)
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
		expect(res.match(/Bookmark 'invalid1' does not exist/)).not_to eq(nil)
		expect(res.match(/Bookmark 'invalid2' does not exist/)).not_to eq(nil)
		expect(res.match(/Bookmark 'valid' does not exist/)).to eq(nil)
		expect(res.match(/Snippet 'invalid3' does not exist/)).not_to eq(nil)
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
		expect(output).not_to eq(output2)
		expect(output2.match(/<p>This is another test.<\/p>/)).not_to eq(nil)

		expect(res.match(/Auto-regeneration enabled/)).not_to eq(nil)
		expect(res.match(/Regeneration started: 1 files changed/)).not_to eq(nil)
		reset_quiet
	end

	it "[compile] should not compile the project in case of an unknown output format" do
		reset_quiet
		expect(run_command_successfully(["compile", "-f", "wrong"])).to eq(false)
	end

	it "[compile] should compile a single source file" do
		reset_quiet
		Dir.chdir Glyph::PROJECT
		file_copy "#{Glyph::PROJECT}/../files/article.glyph", "#{Glyph::PROJECT}/article.glyph"
		file_copy "#{Glyph::PROJECT}/../files/ligature.jpg", "#{Glyph::PROJECT}/ligature.jpg"
		expect(run_command_successfully(["compile", "article.glyph"])).to eq(true)
		expect(Pathname.new('article.html').exist?).to eq(true)
		expect(compact_html(file_load('article.html'))).to eq(compact_html(%{
			<div class="section">
			  改善 Test -- Test Snippet
			</div>
		}))
		(Glyph::PROJECT/'article.html').unlink
		Glyph['document.output'] = 'pdf'
		src = Glyph::PROJECT/'article.html'
		out = Glyph::PROJECT/'article.pdf'
    Glyph.enable 'generate:html'
    Glyph.enable 'generate:pdf'
    Glyph.enable 'generate:pdf_through_html'
    expect(run_command_successfully(["compile", "article.glyph"])).to eq(true)
    expect(src.exist?).to eq(true)
    expect(out.exist?).to eq(true)
    out.unlink
		Glyph.lite_mode = false
	end	

	it "[compile] should compile a single source file to a custom destination" do 
		reset_quiet
		Dir.chdir Glyph::PROJECT
		file_copy "#{Glyph::PROJECT}/../files/article.glyph", "#{Glyph::PROJECT}/article.glyph"
		file_copy "#{Glyph::PROJECT}/../files/ligature.jpg", "#{Glyph::PROJECT}/ligature.jpg"
		expect(run_command_successfully(["compile", "article.glyph", "out/article.htm"])).to eq(true)
		Glyph.lite_mode = false
		expect(Pathname.new('out/article.htm').exist?).to eq(true) 
	end

	it "[compile] should finalize the document in case of errors in included files" do
		create_project
		file_write Glyph::PROJECT/'document.glyph', "section[@title[Test]\ninclude[errors.glyph]\ninclude[syntax_error.glyph]]"
		file_write Glyph::PROJECT/'text/errors.glyph', "not[a|b]"
		file_write Glyph::PROJECT/'text/syntax_error.glyph', "$[a"
		err = "Document cannot be finalized due to previous errors"
		res = run_command(["compile"])
		out = file_load Glyph::PROJECT/'output/html/test_project.html'
		expect(compact_html(out)).to eq(%{<div class="section"><h2 id="h_1" class="toc">Test</h2></div>})
		expect(res.match("error: #{err}")).to eq(nil)
	end

	it "[outline] should display the document outline" do
		create_project
		start = %{=====================================
test_project - Outline
=====================================}
		c_file = "=== container.textile"
		i_file = "=== a/b/c/included.textile"
		m_file = "=== a/b/c/markdown.markdown"
		c_title = "- Container section "
		i_title = "- Test Section "
		m_title = "- Markdown "
		c_id = "[#h_1]"
		i_id = "[#h_2]"
		m_id = "[#md]"
		file_write Glyph::PROJECT/'document.glyph', "document[#{file_load(Glyph::PROJECT/'document.glyph')}]"
		expect(run_command(["-d", "outline"])).to eq(%{#{start}
  #{c_title}
    #{i_title}
  #{m_title}
})
		reset_quiet
		expect(run_command(["outline", "-l", "1"])).to eq(%{#{start}
  #{c_title}
  #{m_title}
})
		reset_quiet
		expect(run_command(["outline", "-ift"])).to eq(%{#{start}
#{c_file}
  #{c_title}#{c_id}
#{i_file}
    #{i_title}#{i_id}
#{m_file}
  #{m_title}#{m_id}
})
	end

	it "[stats] should display project statistics" do
		reset_quiet
		create_project
		out = run_command(["stats", "-ms"])
		total_macros = (Glyph::MACROS.keys - Glyph::ALIASES[:by_alias].keys).uniq.length
		expect(out).to match "-- Total Macro Definitions: #{total_macros}" 
		out = run_command(["stats"])
		expect(out).to match "-- Total Macro Definitions: #{total_macros}" 
		expect(out).to match "-- Total Unreferenced Bookmarks: 3"
		out = run_command(["stats", "-lb", "--bookmark=md"])
		expect(out).to match "-- Unreferenced Bookmarks: h_1, h_2, md" 
		expect(out).to match "-- Defined in: text/a/b/c/markdown.markdown"
		expect(out).not_to match "-- Total Macro Definitions: 19"
	end

end
