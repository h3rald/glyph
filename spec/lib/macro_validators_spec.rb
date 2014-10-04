#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Macro::Validators do

	before do
		create_project
		Glyph.run! 'load:all'
		Glyph.macro :validated_test do
			validate("Invalid Macro"){	value == "valid" }
			"Validated Test: #{value}"
		end
	end

	after do
		reset_quiet
		delete_project
	end

	it "should provide custom validation" do
		expect { interpret("section[validated_test[invalid]]").document.output }.to raise_error Glyph::MacroError
		expect { interpret("chapter[validated_test[valid]]").document.output }.not_to raise_error
	end

	it "should validate the number of parameters" do
		# exact
		expect { interpret("section[sfsdg|saf]").document.output }.to raise_error Glyph::MacroError
		# none
		expect { interpret("title[test]").document.output }.to raise_error Glyph::MacroError
		# min
		expect { interpret("?[]").document.output }.to raise_error Glyph::MacroError
		# max
		expect { interpret("not[a|b|c]").document.output }.to raise_error Glyph::MacroError
		# correct
		expect { interpret("chapter[fmi[something|#something]]").document.output }.not_to raise_error 
	end

	it "should check for mutual inclusion" do
		expect(interpret("&:[inc|Test &[inc]]&[inc] test").document.output).to eq("Test [SNIPPET 'inc' NOT PROCESSED] test")
	end

	it "should validate XML elements" do
		language 'xml'
		expect { interpret("<test[test]").document}.to raise_error
		expect { interpret("_test[test]").document}.not_to raise_error
	end

	it "should validate XML attributes" do
		language 'xml'
		expect(output_for("test[test @.test[test]]")).to eq("<test>test </test>")
	end

	it "should validate required attributes" do
		Glyph['document.output'] = 'web'
		Glyph.run! 'load:macros'
		expect { output_for("section[section[@src[test]]]") }.to raise_error(Glyph::MacroError, "Macro 'section' requires a 'title' attribute")
	end

	it "should validate if a macro is within another one" do
		define_em_macro
		Glyph.macro :within_m do
			within :em
			"---"
		end
		expect { output_for("within_m[test]") }.to raise_error(Glyph::MacroError, "Macro 'within_m' must be within a 'em' macro")
	end	

	it "should validate if a macro is not within another one" do
		define_em_macro
		Glyph.macro :within_m do
			not_within :em
			"---"
		end
		expect { output_for("em[within_m[test]]") }.to raise_error(Glyph::MacroError, "Macro 'within_m' must not be within a 'em' macro")
	end	

end

