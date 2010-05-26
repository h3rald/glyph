#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Macro:" do

	before do
		create_project
		Glyph.run! 'load:all'
	end

	after do
		Glyph.lite_mode = false
		delete_project
	end

	it "snippet" do
		define_em_macro
		interpret "Testing a snippet: &[test]."
		@p.document.output.should == "Testing a snippet: This is a \nTest snippet."
		interpret("Testing &[wrong].")
		@p.document.output.should == "Testing [SNIPPET 'wrong' NOT PROCESSED]." 
		Glyph::SNIPPETS[:a] = "this is a em[test] &[b]"
		Glyph::SNIPPETS[:b] = "and another em[test]"
		text = "TEST: &[a]"
		interpret text
		@p.document.output.should == "TEST: this is a <em>test</em> and another <em>test</em>"
		# Check snippets with links
		Glyph::SNIPPETS[:c] = "This is a link to something afterwards: =>[#other]"
		text = "Test. &[c]. #[other|Test]."
		output_for(text).should == %{Test. This is a link to something afterwards: <a href="#other">Test</a>. <a id="other">Test</a>.}
		# Check mutual inclusion
		Glyph::SNIPPETS[:inc] = "Test &[inc]"
		lambda {interpret("&[inc] test").document}.should raise_error(Glyph::MutualInclusionError)
	end

	it "snippet:" do
		interpret("&[t1] - &:[t1|Test #1] - &[t1]")
		@p.document.output.should == "[SNIPPET 't1' NOT PROCESSED] -  - Test #1"
		Glyph::SNIPPETS[:t1].should == "Test #1"
		Glyph::SNIPPETS.delete :t1
	end

	it "condition" do
		define_em_macro
		interpret("?[$[document.invalid]|em[test]]")
		@p.document.output.should == ""
		interpret("?[$[document.output]|em[test]]")
		@p.document.output.should == "<em>test</em>"
		interpret("?[not[eq[$[document.output]|]]|em[test]]")
		@p.document.output.should == "<em>test</em>"
		interpret %{?[
				or[
					eq[$[document.target]|htmls]|
					not[eq[$[document.author]|x]]
				]|em[test]]}
		@p.document.output.should == "<em>test</em>"
		# "false" should be regarded as false
		interpret(%{?[%["test".blank?]|---]})
		@p.document.output.should == ""
		interpret("?[not[match[$[document.source]|/^docu/]]|em[test]]")
		@p.document.output.should == ""
		# Invalid regexp
		lambda { interpret("?[match[$[document.source]|document]em[test]]").document.output }.should raise_error
		interpret "?[%[lite?]|test]"
		@p.document.output.should == ""
		interpret "?[%[!lite?]|test]"
		@p.document.output.should == "test"
		interpret "?[%[lite?]|%[\"test\"]]"
		@p.document.output.should == ""
		# Condition not satisfied...
		interpret "?[%[lite?]|%[ Glyph\\['test_config'\\] = true ]]"
		@p.document.output.should == ""
		Glyph['test_config'].should_not == true
		# Condition satisfied...
		interpret "?[%[!lite?]|%[ Glyph\\['test_config'\\] = true ]]"
		@p.document.output.should == "true"
		Glyph['test_config'].should == true
	end

	it "comment" do
		output_for("--[config:[some_random_setting|test]]").should == ""
		Glyph[:some_random_setting].should == nil
	end

	it "include" do
		Glyph["filters.by_extension"] = true
		text = file_load(Glyph::PROJECT/'text/container.textile')
		interpret text
		@p.document.output.gsub(/\n|\t|_\d{1,3}/, '').should == %{
			<div class="section">
			<h2 id="h_1">Container section</h2>
			This is a test.
				<div class="section">
				<h3 id="h_2">Test Section</h3>	
				<p>&#8230;</p>
				</div>
			</div>
		}.gsub(/\n|\t|_\d{1,3}/, '')
	end

	it "include should not work in Lite mode" do
		text = file_load(Glyph::PROJECT/'text/container.textile')
		Glyph.lite_mode = true
		lambda { interpret(text).document.output }.should raise_error Glyph::MacroError
		Glyph.lite_mode = false
	end

	it "escape" do
		define_em_macro
		text = %{This is a test em[This can .[=contain test[macros em[test]]=]]}		
		interpret text
		@p.document.output.should == %{This is a test <em>This can contain test[macros em[test]]</em>}
	end

	it "ruby" do
		interpret "2 + 2 = %[2+2]"
		@p.document.output.should == %{2 + 2 = 4}
		interpret "%[lite?]"
		@p.document.output.should == %{false}
		interpret "%[def test; end]"
	end

	it "config" do
		Glyph["test.setting"] = "TEST"
		interpret "test.setting = $[test.setting]"
		@p.document.output.should == %{test.setting = TEST}
	end
	
	it "config:" do
		Glyph["test.setting"] = "TEST"
		interpret "test.setting = $[test.setting]"
		@p.document.output.should == %{test.setting = TEST}
		interpret "test.setting = $:[test.setting|TEST2]$[test.setting]"
		@p.document.output.should == %{test.setting = TEST2}
		Glyph['system.test'] = false
		interpret "$:[system.test|true]"
		# TODO
	end

	it "macro:" do
		interpret '%:[e_macro|
			"Test: #{value}"]e_macro[OK!]'
		@p.document.output.should == "Test: OK!"
	end

end	
