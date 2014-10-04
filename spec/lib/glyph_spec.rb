#!/usr/bin/env ruby

describe Glyph do

	before do
		Glyph.enable 'project:create'
	end

	after do
		delete_project
	end

	it "should initialize a rake app and tasks" do
		expect(Rake.application.tasks.length).to be > 0
	end

	it "should run rake tasks" do
		delete_project_dir
		create_project_dir
		Glyph.run 'project:create', Glyph::PROJECT
		expect { Glyph.run! 'project:create', Glyph::PROJECT }.to raise_error
		delete_project_dir
		create_project_dir
		expect { Glyph.run! 'project:create', Glyph::PROJECT }.not_to raise_error
		delete_project_dir
	end

	it "should define macros" do
		expect { define_em_macro }.not_to raise_error
		expect { define_ref_macro }.not_to raise_error
		expect(Glyph::MACROS.include?(:em)).to eq(true)
		expect(Glyph::MACROS.include?(:ref)).to eq(true)
	end

	it "should support macro aliases" do
		define_ref_macro
		define_em_macro
		expect { Glyph.macro_alias("->" => :ref)}.not_to raise_error
		expect(Glyph::MACROS[:"->"]).to eq(Glyph::MACROS[:ref])
		Glyph.macro_alias :em => :ref
		expect(Glyph::MACROS[:em]).to eq(Glyph::MACROS[:ref])
	end

	it "should provide a filter method to convert raw text into HTML" do
		Glyph['document.title'] = "Test"
		expect(Glyph.filter("title[]").gsub(/\n|\t/, '')).to eq("<h1>Test</h1>")
	end

	it "should provide a compile method to compile files in lite mode" do
		reset_quiet
		file_copy Glyph::PROJECT/'../files/article.glyph', Glyph::PROJECT/'article.glyph'
		#lambda { 
			Glyph.debug_mode = true
			Glyph.compile Glyph::PROJECT/'article.glyph' 
		#}.should_not raise_error
		expect((Glyph::PROJECT/'article.html').exist?).to eq(true)
	end

	it "should provide a reset method to remove config overrides, reenable tasks, clear macros and reps" do
		Glyph['test_setting'] = true
		Glyph.reset
		expect(Glyph::MACROS.length).to eq(0)
		expect(Glyph::REPS.length).to eq(0)
		expect(Glyph['test_setting']).to eq(nil)
	end

	it "should not allow certain macros to be expanded in safe mode" do
		create_project
		Glyph.run! "load:all"
		Glyph.safe_mode = true
		expect { output_for("include[test.glyph]")}.to raise_error Glyph::MacroError
		expect {output_for("config:[test|true]")}.to raise_error Glyph::MacroError
		expect { output_for("ruby[Time.now]")}.to raise_error Glyph::MacroError
		expect { output_for("def:[a|section[{{0}}]]")}.to raise_error Glyph::MacroError
		Glyph.safe_mode = false
	end

	it "should define macros using Glyph syntax" do
		define_em_macro
		Glyph.define :test_def_macro, %{em[{{0}} -- {{a}}]}
		expect(output_for("test_def_macro[@a[!]?]")).to eq("<em>? -- !</em>")
	end

	it "should store alias information" do
		delete_project_dir
		create_project_dir
		Glyph.run! 'project:create', Glyph::PROJECT
		Glyph.run 'load:all'
		expect(Glyph::ALIASES[:by_def][:snippet]).to eq([:&])
		expect(Glyph::ALIASES[:by_alias][:"?"]).to eq(:condition)
		expect(Glyph.macro_aliases_for(:link)).to eq([:"=>"])
		expect(Glyph.macro_aliases_for(:"=>")).to eq(nil)
		expect(Glyph.macro_definition_for(:"=>")).to eq(:link)
		expect(Glyph.macro_definition_for(:link)).to eq(nil)
		expect(Glyph.macro_alias?(:"#")).to eq(true)
	end

	it "should store macro representations" do
		delete_project_dir
		create_project_dir
		Glyph.macro :test_rep do
		end
		Glyph.macro_alias :test_rep_alias  => :test_rep
		Glyph.rep :test_rep do |data|
			"TEST - #{data[:a]}"
		end
		expect(Glyph::REPS[:test_rep].call(:a => 1)).to eq("TEST - 1") 
		expect(Glyph::REPS[:test_rep_alias].call(:a => 1)).to eq("TEST - 1") 
	end

	it "should load reps for a given output" do
		Glyph.reps_for(:html)
		expect(Glyph::REPS[:section]).not_to be_blank
		expect(Glyph::REPS[:link]).not_to be_blank
		expect(Glyph::REPS[:"=>"]).not_to be_blank
	end

end
