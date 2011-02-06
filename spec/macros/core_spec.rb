#!/usr/bin/env ruby

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

	it "condition (else)" do
		output_for("?[true|OK|NOT OK]").should == "OK"
		output_for("?[false|OK|NOT OK]").should == "NOT OK"
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

	it "define:" do
		define_em_macro
		interpret("def:[def_test|em[{{0}}\\.em[{{a}}]]]").process
		output_for("def_test[test @a[em[A!]]]").should == "<em>test<em><em>A!</em></em></em>"
		output_for("def_test[]").should == "<em><em></em></em>"
	end

	it "define should support recursion" do
		fact = %{
			def:[fact|
				?[
					eq[{{0}}|0]|1|
						multiply[
							{{0}} | fact[subtract[{{0}}|1]]
						]
					]
				]
			fact[5]
		}
		output_for(fact).strip.should == "120"
	end

	it "output?" do
		out = Glyph['document.output']
		Glyph['document.output'] = "html"
		output_for("?[output?[html|web]|YES!]").should == "YES!"
		Glyph['document.output'] = "web"
		output_for("?[output?[html|web]|YES!]").should == "YES!"
		Glyph['document.output'] = "web5"
		output_for("?[output?[html|web]|YES!|NO...]").should == "NO..."
	end

	it "let, attribute, attribute:" do
		test = %{
			let[
				@a[1]
				@b[1]
				-- @[a]@[b] --
			]
		}
		nested_test = %{
			section[
				@title[test]
				let[
					-- @[title]@[unknown] --
				]
			]
		}
		set_test = %{
			section[
				@title[test]
				em[-- @[title]@:[title|changed!]@[title] --]
				let[
					@a[1]
					em[@:[title|changed again!]-- @[title] --]
				]
			]
		}
		invalid_set = %{@:[test|1]}
		invalid_macro = %{=>@[test]}
		output_for(test).should match("-- 11 --")
		output_for(nested_test).should match("-- test --")
		output_for(set_test).should match("-- testchanged! --")
		output_for(set_test).should match("-- changed again! --")
		lambda { output_for(invalid_set)}.should raise_error(Glyph::MacroError, "Undeclared attribute 'test'")
		lambda { output_for(invalid_macro) }.should raise_error
		# Set same attribute
		text = %{
			let[
				@a[-]
				em[
					@:[a|s/concat[@[a]|--]]
					@[a]
				]
			]
		}
		output_for(text).strip.should match("---")
	end

	it "add, multiply, subtract" do
		output_for("add[2|2]").should == "4"
		output_for("add[1|2|3|4]").should == "10"
		output_for("add[1|2|-3]").should == "0"
		output_for("add[a|1|2]").should == "3"
		output_for("add[a|test]").should == "0"
		lambda { output_for("add[1]").should == "1"}.should raise_error
		lambda { output_for("add[]").should == "1"}.should raise_error
		output_for("subtract[2|2]").should == "0"
		output_for("subtract[1|2|3|4]").should == "-8"
		output_for("subtract[1|2|-3]").should == "2"
		output_for("subtract[a|1|2]").should == "-3"
		output_for("subtract[a|test]").should == "0"
		lambda { output_for("subtract[1]").should == "1"}.should raise_error
		lambda { output_for("subtract[]").should == "1"}.should raise_error
		output_for("multiply[2|2]").should == "4"
		output_for("multiply[1|2|3|4]").should == "24"
		output_for("multiply[1|2|-3]").should == "-6"
		output_for("multiply[a|1|2]").should == "0"
		output_for("multiply[a|test]").should == "0"
		lambda { output_for("multiply[1]").should == "1"}.should raise_error
		lambda { output_for("multiply[]").should == "1"}.should raise_error
	end

	it "s" do
		lambda { output_for("s/each[test]") }.should raise_error
		lambda { output_for("s/gsub[]") }.should raise_error
		output_for("s/gsub[string|/ri/|i]").should == "sting"
		output_for("s/match[test|/EST/i]").should == "est"
		output_for("s/upcase[test]").should == "TEST"
		output_for("s/insert[hell|4|o]").should == "hello"
		output_for("s/slice[test]").should == ""
	end

	it "lt, lte, gt, gte" do
		lambda { output_for("lt[1|2|3]")}.should raise_error
		output_for("lt[2|7]").should == "true"
		output_for("gt[2|7]").should == ""
		output_for("gte[2|2]").should == "true"
		output_for("lte[2|2]").should == "true"
		output_for("gt[aaa|2]").should == "true"
	end

	it "while" do
		text = %{
			let[
				@count[5]
				@text[-]
				while[gt[@[count]|0]|
					@:[text|s/concat[@[text]|test-]]					
					@:[count|subtract[@[count]|1]]
				]
				@[text]
			]
		}
		output_for(text).strip.should == "-test-test-test-test-test-"
	end

	it "apply" do
		define_em_macro
		lambda { output_for("apply[]") }.should raise_error
		lambda { output_for("apply[a|b|c]") }.should raise_error
		lambda { output_for("apply[a|b]") }.should raise_error
		lambda { output_for("apply[em[a]|b]")}.should raise_error
		output_for("apply['[em[a]]|b]").should == "'[b]"
		output_for("apply['[a]|-{{0}}-]").should == "'[-a-]"
		output_for("apply['[.[@test[1]2|3]]|{{1}}-{{0}}-{{test}}]").should == "'[3-2-1]"
		output_for("map['[.[@a[a1]1+]|.[@a[a2]]|.[3+]]|{{0}}%{{a}}]").should == "'[1+%a1|%a2|3+%]"
	end

	it "quote and unquote" do
		define_em_macro
		output_for("quote[em[test]]").should == "quote[em[test]]"
		output_for("'[em[a]|em[b]]").should == "'[em[a]|em[b]]"
		output_for("unquote[quote[em[test]]]").should == "<em>test</em>"
		output_for("~[quote[em[a]|em[b]]]").should == "<em>a</em><em>b</em>"
		output_for("~['['[em[test]]]]").should == "'[em[test]]"
		lambda { output_for("unquote[...|...]")}.should raise_error
		output_for("unquote[...]").should == "..."
	end

	it "reverse, length" do
		lambda { output_for("reverse[.|.]") }.should raise_error
		lambda { output_for("reverse[.]")}.should raise_error
		output_for("reverse['[1|2|3]]").should == "'[3|2|1]"
		lambda { output_for("length[.|.]") }.should raise_error
		lambda { output_for("length[.]")}.should raise_error
		output_for("length['[]]").should == "0"
		output_for("length['[.]]").should == "1"
		output_for("length['[.|.]]").should == "2"
	end

	it "get" do
		define_em_macro
		lambda { output_for("get[]")}.should raise_error
		lambda { output_for("get[.|.]")}.should raise_error
		output_for("get['[1]|.]").should == "1"
		output_for("get['[1|2|3]|1]").should == "2"
		output_for("get['[1|2|em[3]]|2]").should == "<em>3</em>"
		output_for("get['[1]|4]").should == ""
	end

	it "sort" do
		lambda { output_for("sort[]")}.should raise_error
		lambda { output_for("sort[1|2]")}.should raise_error
		output_for("sort['[5|1|4|2|3|6]]").should == "'[1|2|3|4|5|6]"
		q = "'[.[@a[3]] | .[@a[1]@b[2]] | .[@a[2]1|2|3]]"
		output_for("sort[#{q}|a]").should == "'[ .[@a[1]@b[2]] | .[@a[2]1|2|3]|.[@a[3]] ]" 
		output_for("reverse[sort[#{q}|a]]").should == "'[.[@a[3]] | .[@a[2]1|2|3]| .[@a[1]@b[2]] ]" 
	end

	it "select" do
		lambda { output_for("select[]") }.should raise_error
		lambda { output_for("select[1|2]") }.should raise_error
		output_for("select['[1|2|2|3]|gte[{{0}}|2]]").should == "'[2|2|3]"
		q = "'[ .[@a[1]a|b] | .[@b[1]a] | .[@b[1]@a[2]a|b|c] ]"
		output_for("select[#{q}|{{a}}]").should == "'[.[@a[1]a|b]|.[@b[1]@a[2]a|b|c]]"
		output_for("select[#{q}|or[{{a}}|{{b}}]]").should == "'[.[@a[1]a|b]|.[@b[1]a]|.[@b[1]@a[2]a|b|c]]"
		output_for("filter[#{q}|{{1}}]").should == "'[.[@a[1]a|b]|.[@b[1]@a[2]a|b|c]]"
	end

	it "fragment" do
		text = "... ##[id1|test fragment #1] ... ##[id2|test fragment #2]"
	 	interpret text
		@p.document.fragments.should == {:id1 => "test fragment #1", :id2 => "test fragment #2"}	
		@p.document.output.should == "... test fragment #1 ... test fragment #2"
		lambda { output_for "##[id1|test] -- fragment[id1|test]" }.should raise_error
		lambda { output_for "##[id1]" }.should raise_error
	end

it "embed" do
	text = "... <=[id2] ##[id1|test fragment #1] ... ##[id2|test fragment #2] <=[id1]"
	output_for(text).should == "... test fragment #2 test fragment #1 ... test fragment #2 test fragment #1"
end	



end	
