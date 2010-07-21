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
		@p.document.output.gsub(/\n|\t/, '').should == %{
			<div class="section">
			<h2 id="h_1">Container section</h2>
			This is a test.
				<div class="section">
				<h3 id="h_2">Test Section</h3>	
				<p>&#8230;</p>
				</div>
			</div>
		}.gsub(/\n|\t/, '')
	end

	it "include should work in Lite mode" do
		Glyph.lite_mode = true
		result = %{<div class="section">
<h2 id="h_1">Container section</h2>
This is a test.
	<div class="section">
	<h3 id="h_2">Test Section</h3>
		<p>&#8230;</p>
	</div>

</div>}.gsub(/\n|\t/, '')		
		Dir.chdir Glyph::SPEC_DIR/"files"
		text = file_load(Glyph::SPEC_DIR/"files/container.textile").gsub("a/b/c/", '')
		Glyph.filter(text).gsub(/\n|\t/, '').should == result
		Dir.chdir Glyph::PROJECT
		Glyph.lite_mode = false
	end

	it "include should assume .glyph as the default extension" do
		file_copy Glyph::SPEC_DIR/'files/article.glyph', Glyph::PROJECT/'text/article.glyph'
		output_for("include[article]").gsub(/\n|\t/, '').should == %{<div class="section">
Test -- Test Snippet

</div>}.gsub(/\n|\t/, '')
	end

	it "include should evaluate .rb file in the context of Glyph" do
		text = %{
			macro :day do
				Time.now.day
			end
		}
		file_write Glyph::PROJECT/"lib/test.rb", text
		output_for("include[test.rb]day[]").should == Time.now.day.to_s	
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
		interpret("$:[test.setting]").process
		Glyph['test.setting'].should == nil
		Glyph['system.test'] = 1
		interpret("$:[system.test|2]").process
		Glyph['system.test'].should == 1
	end

	it "macro:" do
		interpret '%:[e_macro|
			"Test: #{value}"]e_macro[OK!]'
		@p.document.output.should == "Test: OK!"
	end

	it "alias:" do
		define_em_macro
		interpret("alias:[test|em]").process
		Glyph::MACROS[:test].should == Glyph::MACROS[:em]
	end

	it "rewrite:" do
		define_em_macro
		interpret("rewrite:[rw_test|em[{{0}}\\.em[{{a}}]]]").process
		output_for("rw_test[test @a[em[A!]]]").should == "<em>test<em><em>A!</em></em></em>"
	end

	it "rewrite should detect mutual definitions" do
		define_em_macro
		lambda do
			interpret("rw:[rw_test2|em[rw_test2[{{0}}]]]").process
		end.should raise_error(Glyph::MacroError)
	end

	it "topic"
		# TODO
		# Store topic contents
		# Return a link
		# Use only in document.glyph
		# Mandatory @title and @src
		# Cannot be used in lite mode
		# Link must be to a DIFFERENT FILE (with the proper extension)

end	
