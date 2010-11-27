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
		lambda { Glyph.run! 'generate:document'}.should_not raise_error
		Glyph.document.structure.children.length.should > 0
	end

	it ":html should generate a standalone html document" do
		lambda { Glyph.run! 'generate:html'}.should_not raise_error
		(Glyph::PROJECT/'output/html/test_project.html').exist?.should == true
	end

  it ":mobi should generate a mobi document" do
		Glyph['document.output'] = 'mobi'
    lambda { stdout_for { Glyph.run! 'generate:mobi'}}.should_not raise_error
		(Glyph::PROJECT/'output/mobi/test_project.mobi').exist?.should == true
  end

  it ":epub should generate an epub document" do
		Glyph['document.output'] = 'epub'
    lambda { stdout_for { Glyph.run! 'generate:epub'}}.should_not raise_error
		(Glyph::PROJECT/'output/epub/test_project.epub').exist?.should == true
  end

	it "should copy images" do
		dir = (Glyph::PROJECT/'images/test').mkpath
		file_copy Glyph::HOME/'spec/files/ligature.jpg', Glyph::PROJECT/'images/test'
		lambda { Glyph.run! 'generate:html' }.should_not raise_error
		(Glyph::PROJECT/'output/html/images/test/ligature.jpg').exist?.should == true
	end

	it "should copy styles if necessary" do
		Glyph['document.styles'] = 'import'
		require 'sass'
		file_write Glyph::PROJECT/'document.glyph', "head[style[default.css]\nstyle[test.sass]]"
		lambda { Glyph.run! 'generate:html' }.should_not raise_error
		(Glyph::PROJECT/'output/html/styles/default.css').exist?.should == true
		(Glyph::PROJECT/'output/html/styles/test.css').exist?.should == true
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
		lambda { Glyph.run! 'generate:web'}.should raise_error(RuntimeError, "You cannot have an 'images' directory under your 'text' directory.")
		reset_web.call
		(Glyph::PROJECT/'text/styles').mkdir
		lambda { Glyph.run! 'generate:web'}.should raise_error(RuntimeError, "You cannot have a 'styles' directory under your 'text' directory.")
		reset_web.call
		# check that the task can be run without errors
		reset_web.call
		Glyph["output.#{Glyph['document.output']}.base"] = "/test/"
		#lambda {
			Glyph.run! 'generate:web'
		#}.should_not raise_error
		# check that images are copied
		(Glyph::PROJECT/'output/web/images/ligature.jpg').exist?.should == true
		# check that stylesheets are copied
		(Glyph::PROJECT/'output/web/styles/default.css').exist?.should == true
		(Glyph::PROJECT/'output/web/styles/test.css').exist?.should == true
		# check that index.html is created
		index = (Glyph::PROJECT/'output/web/index.html')
		index.exist?.should == true
		file_load(index).should match(/<li class="section"><a href="\/test\/a\/b\/web2.html#h_6">Topic #2<\/a>/)
	  #	check that topics are copied in the proper directories
		web1 = (Glyph::PROJECT/'output/web/a/web1.html')
		web1.exist?.should == true
		web2 = (Glyph::PROJECT/'output/web/a/b/web2.html')
		web2.exist?.should == true
		# Check that placeholders are replaced correctly and that links are valid
		file_load(web2).match(/<a href="\/test\/a\/web1\.html#w1_3">Test #1b<\/a>/).blank?.should == false
		file_load(web1).match(/<a href="\/test\/a\/b\/web2\.html#w2_1">Test #2a<\/a>/).blank?.should == false
		file_load(web1).match(/<a href="#w1_3">Test #1b<\/a>/).blank?.should == false
	end


end
