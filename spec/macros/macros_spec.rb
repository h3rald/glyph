#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Macro: " do

	before do
		create_project
		Glyph.run! 'load:macros'
		Glyph.run! 'load:snippets'
		@p = Glyph::Interpreter
	end

	after do
		delete_project
	end

	def define_em_macro
		@p.macro :em do |node| 
			%{<em>#{node[:value]}</em>}
		end
	end

	it "id" do
		@p.process("this is a #[test|test].")[:output].should == "this is a <a id=\"test\">test</a>."
		Glyph::IDS.include?(:test).should == true 
		lambda { @p.process("this is a #[test|test].")}.should raise_error(MacroError, "[--] #: ID 'test' already exists.")
	end

	it "snippet" do
		define_em_macro
		@p.process("Testing a snippet: &[test].")[:output].should == "Testing a snippet: This is a \nTest snippet."
		lambda { @p.process("Testing &[wrong].")}.should raise_error(MacroError)
		Glyph::SNIPPETS[:a] = "this is a em[test] &[b]"
		Glyph::SNIPPETS[:b] = "and another em[test]"
		text = "TEST: &[a]"
		@p.process(text)[:output].should == "TEST: this is a <em>test</em> and another <em>test</em>"
	end

	it "section, chapter, title" do
		text = "chapter[header[Chapter X] ... section[header[Section Y|sec-y] ... section[header[Another section] ...]]]"
		l = Glyph::CONFIG.get("structure.first_header_level")
		@p.process(text)[:output].gsub(/\n|\t|_\d{1,3}/, '').should == %{<div class="chapter">
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

	it "include" do
		l = Glyph::CONFIG.get("structure.first_header_level")
		Glyph.config_override "filters.by_extension", true
		@p.process(file_load(Glyph::PROJECT/'text/container.textile'))[:output].gsub(/\n|\t|_\d{1,3}/, '').should == %{
			<div class="section">
			<h#{l} id="t_Container_section">Container section</h#{l}>
			This is a test.
				<div class="section">
				<h#{l+1} id="t_Test_Section">Test Section</h#{l+1}>	
				<p>&#8230;</p>
				</div>
			</div>
		}.gsub(/\n|\t|_\d{1,3}/, '')
	end


	it "style" do
		@p.process("style[test.sass]")[:output].gsub(/\n|\t/, '').should == "<style>#main {  background-color: #0000ff; }</style>"
	end	

	it "escape" do
		define_em_macro
		text = %{This is a test em[This can .[=contain test[macros em[test]]=]]}		
		@p.process(text)[:output].should == %{This is a test <em>This can contain test[macros em[test]]</em>}
	end

	it "ruby" do
		@p.process("2 + 2 = %[2+2]")[:output].should == %{2 + 2 = 4}
	end

	it "config" do
		Glyph.config_override "test.setting", "TEST"
		@p.process("test.setting = $[test.setting]")[:output].should == %{test.setting = TEST}
	end

	it "toc" do
		file_copy Glyph::PROJECT/'../files/document_with_toc.glyph', Glyph::PROJECT/'document.glyph'
		@p.build_document
		Glyph::DOCUMENT[:output].should == ""
	end


end	
