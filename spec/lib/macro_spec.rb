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
		lambda { @macro.macro_error "Error!" }.should raise_error(Glyph::MacroError)
	end

	it "should interpret strings" do
		@macro.interpret("test[--]").should == "Test: --"
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
		@macro.interpret(text1).should == "->=>Test<=<-"
		@macro.interpret(text2).should == "->int_2\\[Test\\]<-"
		@macro.interpret(text3).should == "->int_2\\[Test\\]<-"
		@macro.interpret(text4).should == "=>->int_1\\[wrong_macro\\[Test\\]\\]<-<="
	end

	it "should store and check bookmarks" do
		h = { :id => "test2", :title => "Test 2", :file => 'test.glyph' }
		@macro.bookmark h
		@doc.bookmark?(:test2).should == Glyph::Bookmark.new(h)
		@macro.bookmark?(:test2).should == Glyph::Bookmark.new(h)
	end

	it "should store and check headers" do
		h = { :level => 2, :id => "test3", :title => "Test 3", :file => "test.glyph"}
		@macro.header h
		@doc.header?("test3").should == Glyph::Bookmark.new(h)
		@macro.header?("test3").should == Glyph::Bookmark.new(h)
	end

	it "should store placeholders" do
		@macro.placeholder { |document| }
		@doc.placeholders.length.should == 1
	end

	it "should expand" do
		@macro.expand.should == "Test: Testing..."
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
		output_for(text).gsub(/\n|\t/, '').should == 
			"ReleaseFeatures: a-2b-3c-4-1"
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
		output_for(text).gsub(/\n|\t/, '').should == 
			"ReleaseFeatures: a-1b-2c-3-4"
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
		m.parameters.should == ["test1: ...", "test1: ---"]
		m.attributes.should == {:a => "test1: ..."}
		m.parameter(0).should == "test1: ..."
		m.parameter(1).should == "test1: ---"
		m.parameter(2).should == nil
		m.attribute(:a).should == "test1: ..."
		m.attribute(:b).should == nil
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
		m.node.parameters.should == [p0, p1]
		m.node.parameters[0][:value].should == nil
		m.node.parameters[1][:value].should == nil
		m.parameter(0).should == "<em>...</em>"
		m.node.parameters[0][:value].should == "<em>...</em>"
		m.node.parameters[1][:value].should == nil
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
		m.node.attributes.should == [p0, p1]
		m.node.attribute(:a)[:value].should == nil
		m.node.attribute(:b)[:value].should == nil
		m.attribute(:a).should == "<em>...</em>"
		m.node.attribute(:a)[:value].should == "<em>...</em>"
		m.node.attribute(:b)[:value].should == nil
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
		output_for("test_ap[]").should == "(!a)(!0)(!1)"
		output_for("test_ap[@a[]|]").should == "(!a)(!0)(!1)"
		output_for("test_ap[@a[.]|]").should == "(a)(!0)(!1)"
		output_for("test_ap[@a[.].|.]").should == "(a)(0)(1)"
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
		m.path.should == "test1/1/b/test2/@a/x"
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
		output_for(text1).should == out
		output_for(text2).should == out
		output_for(text3).should == "- #{out} -"
	end

	it "should render representations" do
		Glyph.macro :em_with_rep do
			@data[:value] = value
			render
		end
		Glyph.rep :em_with_rep do |data|
			%{<em>!#{data[:value]}!</em>}
		end
		output_for("em_with_rep[testing...]").should == "<em>!testing...!</em>"
		Glyph::Macro.new({}).render(:em_with_rep, :value => "test").should == "<em>!test!</em>"
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
		output_for("dispatcher[em[test]]").should == "dispatched: em"
		output_for("dispatcher[em[@attr[test]]]").should == "dispatched: em"
		output_for("dispatcher[...|em[@attr[test]]]").should == "..." # Dispatcher macros should only take one parameter
		output_for("dispatcher[another_macro[test]]").should == "...test"
		output_for("dispatcher[another_macro[another_macro[test]]]").should == "......test"
	end

	it "should apply text with placeholders to macro data" do
		Glyph.macro :data do
			apply "{{1}} {{a}} {{0}}" 
		end
		output_for("data[@a[is]a test|This]").should == "This is a test"
	end

end
