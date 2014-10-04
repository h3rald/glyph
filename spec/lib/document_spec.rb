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
		expect(@doc.bookmarks).to eq({})
		expect(@doc.headers).to eq({})
		expect(@doc.styles).to eq([])
		expect(@doc.placeholders).to eq({})
		expect(@doc.new?).to eq(true)
	end

	it "should store bookmarks" do
		expect { @doc.bookmark(:id => "test", :title => "Test Bookmark #1", :file => 'test.glyph')}.not_to raise_error
		expect { @doc.bookmark(:id => :test, :title => "Test Bookmark #1", :file => 'test.glyph')}.to raise_error
		expect { @doc.bookmark(:id => :test, :title => "Test Bookmark #2", :file => 'test2.glyph')}.to raise_error
		expect(@doc.bookmarks.length).to eq(1)
		expect(@doc.bookmarks[:test]).to eq(Glyph::Bookmark.new(:id => :test, :title => "Test Bookmark #1", :file => "test.glyph"))
	end

	it "should store placeholders" do
		p = lambda { "test" }
		expect { @doc.placeholder &p }.not_to raise_error
		expect(@doc.placeholders["‡‡‡‡‡PLACEHOLDER¤1‡‡‡‡‡".to_sym]).to eq(p)
	end

	it "should store styles" do
		expect {@doc.style "test.css"}.not_to raise_error
		expect(@doc.styles.include?(Pathname.new('test.css'))).to eq(true)
	end

	it "can inherit data from another document" do
		@doc.bookmark :id => :test1, :title => "Test #1", :file => "test.glyph"
		@doc.bookmark :id => :test2, :title => "Test #2", :file => "test.glyph"
		@doc.placeholder { "test" }
		@doc.style "test.css"
		@doc.header :id => :test3, :title => "Test #3", :level => 3, :file => "test.glyph"
		@doc.toc[:contents] = "TOC goes here..."
		doc2 = create_doc @tree
		expect(doc2.bookmarks.length).to eq(0)
		expect(doc2.placeholders.length).to eq(0)
		doc2.bookmark :id => :test4, :title => "Test #4", :file => "test.glyph"
		doc2.inherit_from @doc
		expect(doc2.bookmarks.length).to eq(3)
		expect(doc2.placeholders.length).to eq(1)
		expect(doc2.headers.length).to eq(1)
		expect(doc2.styles.length).to eq(1)
		doc2.toc[:contents] = "TOC goes here..."
		expect(doc2.bookmarks[0]).not_to eq(Glyph::Bookmark.new(:id => :test4, :title => "Test #4", :file => "test.glyph"))
	end

	it "should analyze the syntax tree and finalize the document" do
		expect { @doc.output }.to raise_error
		expect { @doc.finalize }.to raise_error
		expect { @doc.analyze }.not_to raise_error
		expect { @doc.analyze }.to raise_error
		expect(@doc.analyzed?).to eq(true)
		expect { @doc.output }.to raise_error
		expect { @doc.finalize }.not_to raise_error
		expect(@doc.output).to eq("Test: Test: Test: Test|]...")
	end

	it "should expose document structure" do
		expect { @doc.structure }.to raise_error
		@doc.analyze
		expect(@doc.structure.is_a?(Node)).to eq(true)
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
		expect(doc.output.gsub(/\n|\t/, '')[0..14]).to eq("Total: 4 tests.")
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
		expect(doc.output).to eq(result)
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
		expect(doc.toc[:contents].match(%{<div class="contents">}).blank?).to eq(false)
		reset_quiet
	end

	it "should store fragments" do
		delete_project
		create_project
		Glyph.run! "load:all"
		doc = create_doc create_tree("testing ##[frag1|fragments!] -- ##[frag2|another fragment]")
		doc.analyze
		expect(doc.fragments).to eq({:frag1 => "fragments!", :frag2 => "another fragment"})
		reset_quiet
	end

end

