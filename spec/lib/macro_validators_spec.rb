#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Macro::Validators do

	before do
		Glyph.run! 'load:all'
		Glyph.macro :validated_test do
			validate("Invalid Macro"){	@value == "valid" }
			"Validated Test: #{@value}"
		end
	end

	it "should provide custom validation" do
		lambda { interpret("section[validated_test[invalid]]").document.output }.should raise_error Glyph::MacroError
		lambda { interpret("chapter[validated_test[valid]]").document.output }.should_not raise_error
	end

	it "should validate the number of parameters" do
		# exact
		lambda { interpret("table[]").document.output }.should raise_error Glyph::MacroError
		# none
		lambda { interpret("toc[test]").document.output }.should raise_error Glyph::MacroError
		# min
		lambda { interpret("img[]").document.output }.should raise_error Glyph::MacroError
		# max
		lambda { interpret("not[a|b|c]").document.output }.should raise_error Glyph::MacroError
		# correct
		lambda { interpret("chapter[fmi[something|#something]]").document.output }.should_not raise_error Glyph::MacroError
	end

end

