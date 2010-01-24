#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Filter Macros" do

	before do
		create_project
		Glyph.run! 'load:macros'
		@p = Glyph::Preprocessor
	end

	after do
		delete_project
	end
	
	it "should filter textile input" do
		text = "textile[This is a _TEST_(TM).]"
		@p.process(text).should == "<p>This is a <em><span class=\"caps\">TEST</span></em>&#8482;.</p>"
		run_command ["config", "filters.target", :latex]
		@p.process(text).should == "This is a \\emph{TEST}\\texttrademark{}.\n\n"
		run_command ["config", "filters.target", ":html"]
		run_command ["config", "filters.redcloth.restrictions", "[:no_span_caps]"]
		@p.process(text).should == "<p>This is a <em>TEST</em>&#8482;.</p>"
	end

end	
