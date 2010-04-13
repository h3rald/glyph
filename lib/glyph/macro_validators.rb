module Glyph
	class Macro

		module Validators

			def validate(&block)
				macro_error "Macro '#@name' is not allowed here." unless instance_eval(&block)
			end

			def allowed_ancestors(*args)
				validate { @node.find_parent { |n| n[:macro].in? args.map{|a| a.to_sym} }}
			end

			def allowed_parents(*args)
				validate { @node.parent[:macro].in? args.map{|a| a.to_sym} }
			end

		end

	end
end
