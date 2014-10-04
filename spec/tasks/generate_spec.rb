#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "generate" do

	before do
		create_project
	end

	after do
		reset_quiet
		delete_project
	end

	it ":document should generate Glyph.document" do
		expect { Glyph.run! 'generate:document'}.not_to raise_error
		expect(Glyph.document.structure.children.length).to be > 0
	end

	it ":html should generate a standalone html document" do
		expect { Glyph.run! 'generate:html'}.not_to raise_error
		expect((Glyph::PROJECT/'output/html/test_project.html').exist?).to eq(true)
	end

	it ":html5 should generate a standalone html document" do
		Glyph['document.output'] = 'html5'
		expect { Glyph.run! 'generate:html5'}.not_to raise_error
		expect((Glyph::PROJECT/'output/html5/test_project.html').exist?).to eq(true)
	end

  it ":pdf_through_html should generate a pdf document through html" do
		Glyph['document.output'] = 'pdf'
    expect { stdout_for { Glyph.run! 'generate:pdf_through_html'}}.not_to raise_error
		expect((Glyph::PROJECT/'output/tmp/test_project.html').exist?).to eq(true)
		expect((Glyph::PROJECT/'output/pdf/test_project.pdf').exist?).to eq(true)
	end

  it ":pdf_through_html5 should generate a pdf document through html5" do
		Glyph['document.output'] = 'pdf'
    expect { stdout_for { Glyph.run! 'generate:pdf_through_html5'}}.not_to raise_error
		expect((Glyph::PROJECT/'output/tmp/test_project.html').exist?).to eq(true)
		expect((Glyph::PROJECT/'output/pdf/test_project.pdf').exist?).to eq(true)
  end

  it ":mobi should generate a mobi document" do
		Glyph['document.output'] = 'mobi'
    expect { stdout_for { Glyph.run! 'generate:mobi'}}.not_to raise_error
		expect((Glyph::PROJECT/'output/tmp/test_project.html').exist?).to eq(true)
		expect((Glyph::PROJECT/'output/mobi/test_project.mobi').exist?).to eq(true)
  end

  it ":epub should generate an epub document" do
		Glyph['document.output'] = 'epub'
    #lambda { 
			stdout_for { Glyph.run! 'generate:epub'}#}.should_not raise_error
		expect((Glyph::PROJECT/'output/tmp/test_project.html').exist?).to eq(true)
		expect((Glyph::PROJECT/'output/epub/test_project.epub').exist?).to eq(true)
  end

	it "should copy images" do
		dir = (Glyph::PROJECT/'images/test').mkpath
		file_copy Glyph::HOME/'spec/files/ligature.jpg', Glyph::PROJECT/'images/test'
		expect { Glyph.run! 'generate:html' }.not_to raise_error
		expect((Glyph::PROJECT/'output/html/images/test/ligature.jpg').exist?).to eq(true)
	end

	it "should copy styles if necessary" do
		Glyph['document.styles'] = 'import'
		require 'sass'
		file_write Glyph::PROJECT/'document.glyph', "head[style[default.css]\nstyle[test.sass]]"
		expect { Glyph.run! 'generate:html' }.not_to raise_error
		expect((Glyph::PROJECT/'output/html/styles/default.css').exist?).to eq(true)
		expect((Glyph::PROJECT/'output/html/styles/test.css').exist?).to eq(true)
	end

	it ":web should generate multiple html documents" do
		reset_web = lambda do
			delete_project
			reset_quiet
			create_web_project
			Glyph['document.output'] = 'web'
			Glyph['document.styles'] = 'link'
			Glyph.run! 'load:all'
		end
	  # check that the user didn't create a styles or images directory under /text
		reset_web.call
		(Glyph::PROJECT/'text/images').mkdir
		expect { Glyph.run! 'generate:web'}.to raise_error(RuntimeError, "You cannot have an 'images' directory under your 'text' directory.")
		reset_web.call
		(Glyph::PROJECT/'text/styles').mkdir
		expect { Glyph.run! 'generate:web'}.to raise_error(RuntimeError, "You cannot have a 'styles' directory under your 'text' directory.")
		reset_web.call
		# check that the task can be run without errors
		reset_web.call
		Glyph["output.#{Glyph['document.output']}.base"] = "/test/"
		#lambda {
			Glyph.run! 'generate:web'
		#}.should_not raise_error
		# check that images are copied
		expect((Glyph::PROJECT/'output/web/images/ligature.jpg').exist?).to eq(true)
		# check that stylesheets are copied
		expect((Glyph::PROJECT/'output/web/styles/default.css').exist?).to eq(true)
		expect((Glyph::PROJECT/'output/web/styles/test.css').exist?).to eq(true)
		# check that index.html is created
		index = (Glyph::PROJECT/'output/web/index.html')
		expect(index.exist?).to eq(true)
		expect(compact_html(file_load(index))).to match(/<li class="section"><a href="\/test\/a\/b\/web2.html#h_7">Topic #2<\/a>/)
	  #	check that topics are copied in the proper directories
		web1 = (Glyph::PROJECT/'output/web/a/web1.html')
		expect(web1.exist?).to eq(true)
		web2 = (Glyph::PROJECT/'output/web/a/b/web2.html')
		expect(web2.exist?).to eq(true)
		# Check that placeholders are replaced correctly and that links are valid
		expect(file_load(web2).match(/<a href="\/test\/a\/web1\.html#w1_3">Test #1b<\/a>/).blank?).to eq(false)
		expect(file_load(web1).match(/<a href="\/test\/a\/b\/web2\.html#w2_1">Test #2a<\/a>/).blank?).to eq(false)
		expect(file_load(web1).match(/<a href="#w1_3">Test #1b<\/a>/).blank?).to eq(false)
	end


end
