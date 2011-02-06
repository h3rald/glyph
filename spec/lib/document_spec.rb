# encoding: utf-8

#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Document do

	before do
		Glyph.macro :test do |node|
			"Test: #{value}"
		end
		create_tree = lambda {|text| }
		create_doc = lambda {|tree| }
		@tree = create_tree "test[test[test[Test\\|\\]...]]]"
		@doc = create_doc @tree
	end

	it "should expose document data" do
		@doc.bookmarks.should == {}
		@doc.headers.should == {}
		@doc.styles.should == []
		@doc.placeholders.should == {}
		@doc.new?.should == true
	end

	it "should store bookmarks" do
		lambda { @doc.bookmark(:id => "test", :title => "Test Bookmark #1", :file => 'test.glyph')}.should_not raise_error
		lambda { @doc.bookmark(:id => :test, :title => "Test Bookmark #1", :file => 'test.glyph')}.should raise_error
		lambda { @doc.bookmark(:id => :test, :title => "Test Bookmark #2", :file => 'test2.glyph')}.should raise_error
		@doc.bookmarks.length.should == 1
		@doc.bookmarks[:test].should == Glyph::Bookmark.new(:id => :test, :title => "Test Bookmark #1", :file => "test.glyph")
	end

	it "should store placeholders" do
		p = lambda { "test" }
		lambda { @doc.placeholder &p }.should_not raise_error
		@doc.placeholders["‡‡‡‡‡PLACEHOLDER¤1‡‡‡‡‡".to_sym].should == p
	end

	it "should store styles" do
		lambda {@doc.style "test.css"}.should_not raise_error
		@doc.styles.include?(Pathname.new('test.css')).should == true
	end

	it "can inherit data from another document" do
		@doc.bookmark :id => :test1, :title => "Test #1", :file => "test.glyph"
		@doc.bookmark :id => :test2, :title => "Test #2", :file => "test.glyph"
		@doc.placeholder { "test" }
		@doc.style "test.css"
		@doc.header :id => :test3, :title => "Test #3", :level => 3, :file => "test.glyph"
		@doc.toc[:contents] = "TOC goes here..."
		doc2 = create_doc @tree
		doc2.bookmarks.length.should == 0
		doc2.placeholders.length.should == 0
		doc2.bookmark :id => :test4, :title => "Test #4", :file => "test.glyph"
		doc2.inherit_from @doc
		doc2.bookmarks.length.should == 3
		doc2.placeholders.length.should == 1
		doc2.headers.length.should == 1
		doc2.styles.length.should == 1
		doc2.toc[:contents] = "TOC goes here..."
		doc2.bookmarks[0].should_not == Glyph::Bookmark.new(:id => :test4, :title => "Test #4", :file => "test.glyph")
	end

	it "should analyze the syntax tree and finalize the document" do
		lambda { @doc.output }.should raise_error
		lambda { @doc.finalize }.should raise_error
		lambda { @doc.analyze }.should_not raise_error
		lambda { @doc.analyze }.should raise_error
		@doc.analyzed?.should == true
		lambda { @doc.output }.should raise_error
		lambda { @doc.finalize }.should_not raise_error
		@doc.output.should == "Test: Test: Test: Test|]..."
	end

	it "should expose document structure" do
		lambda { @doc.structure }.should raise_error
		@doc.analyze
		@doc.structure.is_a?(Node).should == true
	end

	it "should substitute placeholders when finalizing" do
		Glyph.macro :count_tests do
			n = placeholder do |document|
				count = 0
				document.structure.descend do |node, level|
					count +=1 if node[:name] == :test
				end
				count
			end
			n
		end
		text = %{
		Total: count_tests[] tests.
		test[
			test[
				test[
					test
				]
			]
			test[test]
		]
		}
		tree = create_tree text
		doc = create_doc tree
		doc.analyze
		doc.finalize
		doc.output.gsub(/\n|\t/, '')[0..14].should == "Total: 4 tests."
	end

	it "should substitute escaped pipes only when finalizing the document" do
		define_em_macro
		define_ref_macro
		text = %{em[ref[link with ref[fake \\| parameter|.]|.]]}
		# Nevermind the absurdity. It's just to test that the escaped pipes 
		# are handled properly.
		result = %{<em><a href="link with <a href="fake | parameter">.</a>">.</a></em>}
		tree = create_tree text
		doc = create_doc tree
		doc.analyze
		doc.finalize
		doc.output.should == result
	end

	it "should store the Table of Contents" do
		delete_project
		create_project
		Glyph.run! "load:all"
		text = %{
			document[
				body[
					toc[]
					section[
						@title[test 1]
						...
						section[
							@title[test 2]
							...
						]
					]
				]
			]
		}
		tree = create_tree text
		doc = create_doc tree
		doc.analyze
		doc.finalize
		doc.toc[:contents].match(%{<div class="contents">}).blank?.should == false
		reset_quiet
	end

	it "should store fragments" do
		delete_project
		create_project
		Glyph.run! "load:all"
		doc = create_doc create_tree("testing ##[frag1|fragments!] -- ##[frag2|another fragment]")
		doc.analyze
		doc.fragments.should == {:frag1 => "fragments!", :frag2 => "another fragment"}
		reset_quiet
	end

end

