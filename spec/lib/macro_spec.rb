#!/usr/bin/env ruby

describe Glyph::Macro do

	before do
		Glyph.macro :test do
			"Test: #{value}"
		end
		create_tree = lambda {|text| }
		create_doc = lambda {|tree| }
		@text = "test[section[header[Test!|test]]]"
		@tree = create_tree @text 
		@doc = create_doc @tree
		@node = Glyph::MacroNode.new.from({:name => :test, :source => {:name => "--"}, :document => @doc})
		@node << Glyph::ParameterNode.new.from({:name => :"0"})
		(@node&0) << Glyph::TextNode.new.from({:value => "Testing..."})
		@macro = Glyph::Macro.new @node
	end

	it "should raise macro errors" do
		expect { @macro.macro_error "Error!" }.to raise_error(Glyph::MacroError)
	end

	it "should interpret strings" do
		expect(@macro.interpret("test[--]")).to eq("Test: --")
	end

	it "should not interpret escaped macros" do
		Glyph.macro :int_1 do
			"->#{interpret(value)}<-"
		end
		Glyph.macro :int_2 do
			"=>#{interpret(value)}<="
		end
		text1 = "int_1[int_2[Test]]"
		text2 = "int_1[=int_2[Test]=]"
		text3 = "int_1[=int_2\\[Test\\]=]"
		text4 = "int_2[int_1[=int_1[wrong_macro[Test]]=]]"
		expect(@macro.interpret(text1)).to eq("->=>Test<=<-")
		expect(@macro.interpret(text2)).to eq("->int_2\\[Test\\]<-")
		expect(@macro.interpret(text3)).to eq("->int_2\\[Test\\]<-")
		expect(@macro.interpret(text4)).to eq("=>->int_1\\[wrong_macro\\[Test\\]\\]<-<=")
	end

	it "should store and check bookmarks" do
		h = { :id => "test2", :title => "Test 2", :file => 'test.glyph' }
		@macro.bookmark h
		expect(@doc.bookmark?(:test2)).to eq(Glyph::Bookmark.new(h))
		expect(@macro.bookmark?(:test2)).to eq(Glyph::Bookmark.new(h))
	end

	it "should store and check headers" do
		h = { :level => 2, :id => "test3", :title => "Test 3", :file => "test.glyph"}
		@macro.header h
		expect(@doc.header?("test3")).to eq(Glyph::Bookmark.new(h))
		expect(@macro.header?("test3")).to eq(Glyph::Bookmark.new(h))
	end

	it "should store placeholders" do
		@macro.placeholder { |document| }
		expect(@doc.placeholders.length).to eq(1)
	end

	it "should expand" do
		expect(@macro.expand).to eq("Test: Testing...")
	end

	it "should support rewriting" do
		test = 0
		Glyph.macro :test do
			interpret "#{@node.value}-#{test+=1}"
		end
		Glyph.macro :release do
			interpret "Release\n#{@node.value}"
		end
		Glyph.macro :features do
			interpret "\n\ntest[Features: \n#{@node.value}]"
		end
		Glyph.macro :feature do
			interpret "test[#{@node.value}]\n"
		end
		text = %{
			release[
				features[
					feature[a]
					feature[b]
					feature[c]
				]
			]
		}
		expect(output_for(text).gsub(/\n|\t/, '')).to eq( 
			"ReleaseFeatures: a-2b-3c-4-1"
		)
		test = 0
		Glyph.macro :test do
			interpret "#{value}-#{test+=1}"
		end
		Glyph.macro :release do
			interpret "Release\n#{value}"
		end
		Glyph.macro :features do
			interpret "\n\ntest[Features: \n#{value}]"
		end
		Glyph.macro :feature do
			interpret "test[#{value}]\n"
		end
		expect(output_for(text).gsub(/\n|\t/, '')).to eq( 
			"ReleaseFeatures: a-1b-2c-3-4"
		)
	end

	it "should support access to parameters and attributes" do
		Glyph.macro :test do
			"test: #{value}"
		end
		Glyph.macro :test1 do
			"test1: #{value}"
		end
		node = Glyph::Parser.new("test[@a[test1[...]]test1[...]|test1[---]]").parse
		m = Glyph::Macro.new(node&0)
		expect(m.parameters).to eq(["test1: ...", "test1: ---"])
		expect(m.attributes).to eq({:a => "test1: ..."})
		expect(m.parameter(0)).to eq("test1: ...")
		expect(m.parameter(1)).to eq("test1: ---")
		expect(m.parameter(2)).to eq(nil)
		expect(m.attribute(:a)).to eq("test1: ...")
		expect(m.attribute(:b)).to eq(nil)
	end

	it "should not evaluate attributes unless specifically requested" do
		define_em_macro
		node = Glyph::Parser.new("par0[em[...]|em[---]]").parse
		m = Glyph::Macro.new(node&0)
		syntaxnode = lambda do |hash|
			Glyph::SyntaxNode.new.from hash
		end
		p0 = p_node 0
		p0 << macro_node(:em, :escape => false)
		p00 = p_node 0
		(p0&0) << p00
		p00 << text_node("...")
		p1 = p_node 1
		p1 << macro_node(:em, :escape => false)
		p10 = p_node 0
		(p1&0) << p10
		p10 << text_node("---")
		expect(m.node.parameters).to eq([p0, p1])
		expect(m.node.parameters[0][:value]).to eq(nil)
		expect(m.node.parameters[1][:value]).to eq(nil)
		expect(m.parameter(0)).to eq("<em>...</em>")
		expect(m.node.parameters[0][:value]).to eq("<em>...</em>")
		expect(m.node.parameters[1][:value]).to eq(nil)
	end

	it "should not evaluate parameters unless specifically requested" do
		define_em_macro
		node = Glyph::Parser.new("par0[@a[em[...]]@b[em[---]]]").parse
		m = Glyph::Macro.new(node&0)
		syntaxnode = lambda do |hash|
			Glyph::SyntaxNode.new.from hash
		end
		p0 = a_node :a, :escape => false
		p0 << macro_node(:em, :escape => false)
		p00 = p_node 0
		(p0&0) << p00
		p00 << text_node("...")
		p1 = a_node :b, :escape => false
		p1 << macro_node(:em, :escape => false)
		p10 = p_node 0
		(p1&0) << p10
		p10 << text_node("---")
		expect(m.node.attributes).to eq([p0, p1])
		expect(m.node.attribute(:a)[:value]).to eq(nil)
		expect(m.node.attribute(:b)[:value]).to eq(nil)
		expect(m.attribute(:a)).to eq("<em>...</em>")
		expect(m.node.attribute(:a)[:value]).to eq("<em>...</em>")
		expect(m.node.attribute(:b)[:value]).to eq(nil)
	end

	it "should treat empty parameters/attributes as null" do
		Glyph.macro :test_ap do
			result = ""
			if attr(:a) then
				result << "(a)"
			else
				result << "(!a)"
			end
			if param(0) then
				result << "(0)"
			else
				result << "(!0)"
			end
			if param(1) then
				result << "(1)"
			else
				result << "(!1)"
			end
			result
		end
		expect(output_for("test_ap[]")).to eq("(!a)(!0)(!1)")
		expect(output_for("test_ap[@a[]|]")).to eq("(!a)(!0)(!1)")
		expect(output_for("test_ap[@a[.]|]")).to eq("(a)(!0)(!1)")
		expect(output_for("test_ap[@a[.].|.]")).to eq("(a)(0)(1)")
	end

	it "should expose a path method to determine its location" do
		tree = Glyph::Parser.new(%{
		test1[
			a[...]|
			b[
				test2[@a[x[]]]
			]
		]}).parse
		node = tree&1&1&1&0&1&0&0
		m = Glyph::Macro.new(node)
		expect(m.path).to eq("test1/1/b/test2/@a/x")
	end

	it "should substitute bracket escapes properly" do
		define_em_macro
		Glyph.macro :test_int do
			interpret "- #{value} -"
		end
		text1 = "em[test\\\\\\/\\[...\\\\\\/\\]]" # test\\\/\[\\\/\]
		text2 = "em[=test\\\\\\/[...\\\\\\/]=]"  # test\\\/[\\\/]
		text3 = "test_int[em[=test\\\\\\/[...\\\\\\/]=]]"
		out = "<em>test\\[...\\]</em>"
		expect(output_for(text1)).to eq(out)
		expect(output_for(text2)).to eq(out)
		expect(output_for(text3)).to eq("- #{out} -")
	end

	it "should render representations" do
		Glyph.macro :em_with_rep do
			@data[:value] = value
			render
		end
		Glyph.rep :em_with_rep do |data|
			%{<em>!#{data[:value]}!</em>}
		end
		expect(output_for("em_with_rep[testing...]")).to eq("<em>!testing...!</em>")
		expect(Glyph::Macro.new({}).render(:em_with_rep, :value => "test")).to eq("<em>!test!</em>")
	end

	it "should perform dispatching" do
		Glyph.macro :dispatcher do
			dispatch do |node|
				"dispatched: #{node[:name]}" if node[:name] == :em
			end
		end
		Glyph.macro :another_macro do
			"...#{value}"
		end
		define_em_macro
		expect(output_for("dispatcher[em[test]]")).to eq("dispatched: em")
		expect(output_for("dispatcher[em[@attr[test]]]")).to eq("dispatched: em")
		expect(output_for("dispatcher[...|em[@attr[test]]]")).to eq("...") # Dispatcher macros should only take one parameter
		expect(output_for("dispatcher[another_macro[test]]")).to eq("...test")
		expect(output_for("dispatcher[another_macro[another_macro[test]]]")).to eq("......test")
	end

	it "should apply text with placeholders to macro data" do
		Glyph.macro :data do
			apply "{{1}} {{a}} {{0}}" 
		end
		expect(output_for("data[@a[is]a test|This]")).to eq("This is a test")
	end

end
