#!/usr/bin/env ruby
# encoding: utf-8

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
		interpret "&:[test|This is a \nTest snippet]Testing a snippet: &[test]."
		expect(@p.document.output).to eq("Testing a snippet: This is a \nTest snippet.")
		interpret("Testing &[wrong].")
		expect(@p.document.output).to eq("Testing [SNIPPET 'wrong' NOT PROCESSED].") 
		text = "&:[b|and another em[test]]&:[a|this is a em[test] &[b]]TEST: &[a]"
		interpret text
		expect(@p.document.output).to eq("TEST: this is a <em>test</em> and another <em>test</em>")
		# Check snippets with links
		text = "&:[c|This is a link to something afterwards: =>[#other]]Test. &[c]. #[other|Test]."
		expect(output_for(text)).to eq(%{Test. This is a link to something afterwards: <a href="#other">Test</a>. <a id="other">Test</a>.})
	end

	it "snippet:" do
		interpret("&[t1] - &:[t1|Test #1] - &[t1]")
		expect(@p.document.output).to eq("[SNIPPET 't1' NOT PROCESSED] -  - Test #1")
		expect(@p.document.snippet?(:t1)).to eq("Test #1")
	end

	it "condition" do
		define_em_macro
		interpret("?[$[document.invalid]|em[test]]")
		expect(@p.document.output).to eq("")
		interpret("?[$[document.output]|em[test]]")
		expect(@p.document.output).to eq("<em>test</em>")
		interpret("?[not[eq[$[document.output]|]]|em[test]]")
		expect(@p.document.output).to eq("<em>test</em>")
		interpret %{?[
				or[
					eq[$[document.target]|htmls]|
					not[eq[$[document.author]|x]]
				]|em[test]]}
		expect(@p.document.output).to eq("<em>test</em>")
		# "false" should be regarded as false
		interpret(%{?[%["test".blank?]|---]})
		expect(@p.document.output).to eq("")
		interpret("?[not[match[$[document.source]|/^docu/]]|em[test]]")
		expect(@p.document.output).to eq("")
		interpret "?[%[lite?]|test]"
		expect(@p.document.output).to eq("")
		interpret "?[%[!lite?]|test]"
		expect(@p.document.output).to eq("test")
		interpret "?[%[lite?]|%[\"test\"]]"
		expect(@p.document.output).to eq("")
		# Condition not satisfied...
		interpret "?[%[lite?]|%[ Glyph\\['test_config'\\] = true ]]"
		expect(@p.document.output).to eq("")
		expect(Glyph['test_config']).not_to eq(true)
		# Condition satisfied...
		interpret "?[%[!lite?]|%[ Glyph\\['test_config'\\] = true ]]"
		expect(@p.document.output).to eq("true")
		expect(Glyph['test_config']).to eq(true)
	end

	it "condition (else)" do
		expect(output_for("?[true|OK|NOT OK]")).to eq("OK")
		expect(output_for("?[false|OK|NOT OK]")).to eq("NOT OK")
	end

	it "comment" do
		expect(output_for("--[config:[some_random_setting|test]]")).to eq("")
		expect(Glyph[:some_random_setting]).to eq(nil)
	end

	it "include" do
		Glyph["filters.by_extension"] = true
		text = file_load(Glyph::PROJECT/'text/container.textile')
		interpret text
		expect(@p.document.output.gsub(/\n|\t/, '')).to eq(%{
			<div class="section">
			<h2 id="h_1" class="toc">Container section</h2>
			This is a test.
				<div class="section">
				<h3 id="h_2" class="toc">Test Section</h3>	
				<p>&#8230;</p>
				</div>
			</div>
		}.gsub(/\n|\t/, ''))
	end

	it "include should work in Lite mode" do
		Glyph.lite_mode = true
		result = %{<div class="section">
<h2 id="h_1" class="toc">Container section</h2>
This is a test.
	<div class="section">
	<h3 id="h_2" class="toc">Test Section</h3>
		<p>&#8230;</p>
	</div>

</div>}.gsub(/\n|\t/, '')		
		Dir.chdir Glyph::SPEC_DIR/"files"
		text = file_load(Glyph::SPEC_DIR/"files/container.textile").gsub("a/b/c/", '')
		expect(Glyph.filter(text).gsub(/\n|\t/, '')).to eq(result)
		Dir.chdir Glyph::PROJECT
		Glyph.lite_mode = false
	end

	it "include should assume .glyph as the default extension" do
		file_copy Glyph::SPEC_DIR/'files/article.glyph', Glyph::PROJECT/'text/article.glyph'
		expect(output_for("include[article]").gsub(/\n|\t/, '')).to eq(%{<div class="section">
改善 Test -- Test Snippet

</div>}.gsub(/\n|\t/, ''))
	end

	it "include should evaluate .rb file in the context of Glyph" do
		text = %{
			macro :day do
				Time.now.day
			end
		}
		file_write Glyph::PROJECT/"lib/test.rb", text
		expect(output_for("include[test.rb]day[]")).to eq(Time.now.day.to_s)	
	end

	it "load" do
		text1 = %{section[@title[...]]}
		text2 = %{Time.now.day}
		file_write Glyph::PROJECT/"test1.glyph", text1
		file_write Glyph::PROJECT/"test2.rb", text2
		expect(output_for("load[test/test1.glyph]")).to eq("[FILE 'test/test1.glyph' NOT FOUND]")
		expect(output_for("load[test1.glyph]")).to eq(text1)
		expect(output_for("load[test2.rb]")).to eq(text2)
	end


	it "escape" do
		define_em_macro
		text = %{This is a test em[This can .[=contain test[macros em[test]]=]]}		
		interpret text
		expect(@p.document.output).to eq(%{This is a test <em>This can contain test[macros em[test]]</em>})
	end

	it "ruby" do
		interpret "2 + 2 = %[2+2]"
		expect(@p.document.output).to eq(%{2 + 2 = 4})
		interpret "%[lite?]"
		expect(@p.document.output).to eq(%{false})
		interpret "%[def test; end]"
	end

	it "config" do
		Glyph["test.setting"] = "TEST"
		interpret "test.setting = $[test.setting]"
		expect(@p.document.output).to eq(%{test.setting = TEST})
	end
	
	it "config:" do
		Glyph["test.setting"] = "TEST"
		interpret "test.setting = $[test.setting]"
		expect(@p.document.output).to eq(%{test.setting = TEST})
		interpret "test.setting = $:[test.setting|TEST2]$[test.setting]"
		expect(@p.document.output).to eq(%{test.setting = TEST2})
		interpret("$:[test.setting]").process
		expect(Glyph['test.setting']).to eq(nil)
		Glyph['system.test'] = 1
		interpret("$:[system.test|2]").process
		expect(Glyph['system.test']).to eq(1)
	end

	it "macro:" do
		interpret '%:[e_macro|
			"Test: #{value}"]e_macro[OK!]'
		expect(@p.document.output).to eq("Test: OK!")
	end

	it "alias:" do
		define_em_macro
		interpret("alias:[test|em]").process
		expect(Glyph::MACROS[:test]).to eq(Glyph::MACROS[:em])
	end

	it "define:" do
		define_em_macro
		interpret("def:[def_test|em[{{0}}\\/em[{{a}}]]]").process
		expect(output_for("def_test[test @a[em[A!]]]")).to eq("<em>test<em><em>A!</em></em></em>")
		expect(output_for("def_test[]")).to eq("<em><em></em></em>")
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
		expect(output_for(fact).strip).to eq("120")
	end

	it "output?" do
		out = Glyph['document.output']
		Glyph['document.output'] = "html"
		expect(output_for("?[output?[html|web]|YES!]")).to eq("YES!")
		Glyph['document.output'] = "web"
		expect(output_for("?[output?[html|web]|YES!]")).to eq("YES!")
		Glyph['document.output'] = "web5"
		expect(output_for("?[output?[html|web]|YES!|NO...]")).to eq("NO...")
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
		expect(output_for(test)).to match("-- 11 --")
		expect(output_for(nested_test)).to match("-- test --")
		expect(output_for(set_test)).to match("-- testchanged! --")
		expect(output_for(set_test)).to match("-- changed again! --")
		expect { output_for(invalid_set)}.to raise_error(Glyph::MacroError, "Undeclared attribute 'test'")
		expect { output_for(invalid_macro) }.to raise_error
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
		expect(output_for(text).strip).to match("---")
	end

	it "add, multiply, subtract" do
		expect(output_for("add[2|2]")).to eq("4")
		expect(output_for("add[1|2|3|4]")).to eq("10")
		expect(output_for("add[1|2|-3]")).to eq("0")
		expect(output_for("add[a|1|2]")).to eq("3")
		expect(output_for("add[a|test]")).to eq("0")
		expect { expect(output_for("add[1]")).to eq("1")}.to raise_error
		expect { expect(output_for("add[]")).to eq("1")}.to raise_error
		expect(output_for("subtract[2|2]")).to eq("0")
		expect(output_for("subtract[1|2|3|4]")).to eq("-8")
		expect(output_for("subtract[1|2|-3]")).to eq("2")
		expect(output_for("subtract[a|1|2]")).to eq("-3")
		expect(output_for("subtract[a|test]")).to eq("0")
		expect { expect(output_for("subtract[1]")).to eq("1")}.to raise_error
		expect { expect(output_for("subtract[]")).to eq("1")}.to raise_error
		expect(output_for("multiply[2|2]")).to eq("4")
		expect(output_for("multiply[1|2|3|4]")).to eq("24")
		expect(output_for("multiply[1|2|-3]")).to eq("-6")
		expect(output_for("multiply[a|1|2]")).to eq("0")
		expect(output_for("multiply[a|test]")).to eq("0")
		expect { expect(output_for("multiply[1]")).to eq("1")}.to raise_error
		expect { expect(output_for("multiply[]")).to eq("1")}.to raise_error
	end

	it "s" do
		expect { output_for("s/each[test]") }.to raise_error
		expect { output_for("s/gsub[]") }.to raise_error
		expect(output_for("s/gsub[string|/ri/|i]")).to eq("sting")
		expect(output_for("s/match[test|/EST/i]")).to eq("est")
		expect(output_for("s/upcase[test]")).to eq("TEST")
		expect(output_for("s/insert[hell|4|o]")).to eq("hello")
		expect(output_for("s/slice[test]")).to eq("")
	end

	it "lt, lte, gt, gte" do
		expect { output_for("lt[1|2|3]")}.to raise_error
		expect(output_for("lt[2|7]")).to eq("true")
		expect(output_for("gt[2|7]")).to eq("")
		expect(output_for("gte[2|2]")).to eq("true")
		expect(output_for("lte[2|2]")).to eq("true")
		expect(output_for("gt[aaa|2]")).to eq("true")
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
		expect(output_for(text).strip).to eq("-test-test-test-test-test-")
	end

	it "fragment" do
		text = "... ##[id1|test fragment #1] ... ##[id2|test fragment #2]"
	 	interpret text
		expect(@p.document.fragments).to eq({:id1 => "test fragment #1", :id2 => "test fragment #2"})	
		expect(@p.document.output).to eq("... test fragment #1 ... test fragment #2")
		expect { output_for "##[id1|test] -- fragment[id1|test]" }.to raise_error
		expect { output_for "##[id1]" }.to raise_error
	end

it "embed" do
	text = "... <=[id2] ##[id1|test fragment #1] ... ##[id2|test fragment #2] <=[id1]"
	expect(output_for(text)).to eq("... test fragment #2 test fragment #1 ... test fragment #2 test fragment #1")
end	



end	
