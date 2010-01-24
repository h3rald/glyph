#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Preprocessor::Actions do

	before do
		create_project
		Glyph.run! 'load:macros'
		Glyph.run! 'load:snippets'
		@p = Glyph::Preprocessor
	end

	after do
		delete_project
	end

	def define_em_macro
		@p.macro :em do |node| 
			%{<em>#{node[:value]}</em>}
		end
	end

	it "should store IDs" do
		@p.process("this is a #[test|test].").should == "this is a <a id=\"test\">test</a>."
		Glyph::IDS.include?(:test).should == true 
		lambda { @p.process("this is a #[test|test].")}.should raise_error(MacroError, "[--] #: ID 'test' already exists.")
	end

	it "should support snippets" do
		@p.process("Testing a snippet: &[test].").should == "Testing a snippet: This is a \nTest snippet."
		lambda { @p.process("Testing &[wrong].")}.should raise_error(MacroError)
	end
	
	it "should allod macros within snippets" do
		define_em_macro
		Glyph::SNIPPETS[:a] = "this is a em[test] &[b]"
		Glyph::SNIPPETS[:b] = "and another em[test]"
		text = "TEST: &[a]"
		@p.process(text).should == "TEST: this is a <em>test</em> and another <em>test</em>"
	end

	it "should manage sections and titles" do
		text = "chapter[title[Chapter X] ... section[title[Section Y|sec-y] ... section[title[Another section] ...]]]"
		l = Glyph::CONFIG.get(:first_heading_level)
		@p.process(text).gsub(/\n|\t|_\d{1,3}/, '').should == %{<div class="section">
					<h#{l} id="t_Chapter_X">Chapter X</h#{l}> ... 
					<div class="section">
					<h#{l+1} id="sec-y">Section Y</h#{l+1}> ... 
						<div class="section">
						<h#{l+2} id="t_Another_section">Another section</h#{l+2}> ...
						</div>
					</div>
				</div>
		}.gsub(/\n|\t|_\d{1,3}/, '')
		Glyph::IDS.include?(:"sec-y").should == true 
	end

	it "should support file inclusion" do
		file_copy Glyph::SPEC_DIR/'files/container.textile', Glyph::PROJECT/'text/container.textile'
		(Glyph::PROJECT/'text/a/b/c').mkpath
		file_copy Glyph::SPEC_DIR/'files/included.textile', Glyph::PROJECT/'text/a//b/c/included.textile'
		l = Glyph::CONFIG.get(:first_heading_level)
		@p.process(file_load(Glyph::PROJECT/'text/container.textile')).gsub(/\n|\t|_\d{1,3}/, '').should == %{
			<div class="section">
			<h#{l} id="t_Container_section">Container section</h#{l}>
			This is a test.
				<div class="section">
				<h#{l+1} id="t_Test_Section">Test Section</h#{l+1}>
				...
				</div>
			</div>
		}.gsub(/\n|\t|_\d{1,3}/, '')
	end

end	
