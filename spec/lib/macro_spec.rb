#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

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
		@node = Glyph::Parser::SyntaxNode.new.from({:name => :test, :type=>:macro, :source => "--", :document => @doc})
		@node << Glyph::Parser::SyntaxNode.new.from({:type => :parameter, :name => :"|0|"})
		(@node&0) << Glyph::Parser::SyntaxNode.new.from({:type => :text, :value => "Testing..."})
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
		h = { :id => "test2", :title => "Test 2" }
		@macro.bookmark h
		@doc.bookmark?(:test2).should == h
		@macro.bookmark?(:test2).should == h
	end

	it "should store and check headers" do
		h = { :level => 2, :id => "test3", :title => "Test 3" }
		@macro.header h
		@doc.header?("test3").should == h
		@macro.header?("test3").should == h
	end

	it "should store placeholders" do
		@macro.placeholder { |document| }
		@doc.placeholders.length.should == 1
	end

	it "should execute" do
		@macro.expand.should == "Test: Testing..."
	end

	it "should encode and decode text" 
=begin
	do
		Glyph.run! "load:all"
		Glyph.macro :sec_1 do
			res = decode "section[header[Test1]\n#{value}]"
			interpret res
		end
		Glyph.macro :sec_2 do
			encode "section[section[header[Test2]\n#{value}]]"
		end
		text1 = %{sec_1[sec_2[Test]]}
		interpret text1
		res1 = @p.document.output.gsub(/\t/, '')
		text2 = %{section[header[Test1]
			section[section[header[Test2]
			Test]]]}
		interpret text2
		res2 = @p.document.output.gsub(/\t/, '')
		result = "<div class=\"section\">
				<h2 id=\"h_1\">Test1</h2>
				<div class=\"section\">
					<div class=\"section\">
						<h4 id=\"h_2\">Test2</h4>
						Test

					</div>

				</div>

			</div>".gsub(/\t/, '')
		res1.should == result
		res2.should == result
	end
=end

	it "should support access to parameters and attributes" do
		Glyph.macro :test do
			"test: #{value}"
		end
		Glyph.macro :test1 do
			"test1: #{value}"
		end
		syntaxnode = lambda do |hash|
			Glyph::Parser::SyntaxNode.new.from hash
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

end
