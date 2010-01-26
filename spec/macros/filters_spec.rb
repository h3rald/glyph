#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Filter Macros" do

	before do
		create_project
		Glyph.run! 'load:macros'
		@p = Glyph::Interpreter
	end

	after do
		delete_project
	end
	
	it "should filter textile input" do
		text = "textile[This is a _TEST_(TM).]"
		@p.process(text)[:output].should == "<p>This is a <em><span class=\"caps\">TEST</span></em>&#8482;.</p>"
		run_command ["config", "filters.target", :latex]
		@p.process(text)[:output].should == "This is a \\emph{TEST}\\texttrademark{}.\n\n"
		run_command ["config", "filters.target", ":html"]
		run_command ["config", "filters.redcloth.restrictions", "[:no_span_caps]"]
		@p.process(text)[:output].should == "<p>This is a <em>TEST</em>&#8482;.</p>"
	end

	it "should filter markdown input" do
		text = "markdown[This is a test:

- item 1
- item 2
- item 3

...]"
		@p.process(text)[:output].gsub(/\n|\t/, '').should == 
			"<p>This is a test:</p><ul><li>item 1</li><li>item 2</li><li>item 3</li></ul><p>...</p>"
	end

end	
