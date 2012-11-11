# encoding: utf-8

include GLI::App

version Glyph::VERSION
program_desc "A rapid document authoring framework"

d "Enable debugging"
switch [:d, :debug]

d "Display documentation"
switch [:h, :help]

commands_from Glyph::LIB/"commands"

Glyph.run 'load:tasks'
Glyph.run 'load:commands'

pre do |global,command,options,args|
	# Pre logic here
	# Return true to proceed; false to abort and not call the
	# chosen command
	if global[:d] then
		Glyph.debug_mode = true
	end
  true
end

post do |global,command,options,args|
	# Post logic here
end

on_error do |exception|
	raise if Glyph.library?
	if exception.is_a? Glyph::MacroError then
		exception.display
	else
		Glyph.warning exception.message
		if Glyph.debug? then
			puts "\n"+"-"*20+"[ Backtrace: ]"+"-"*20
			puts "Backtrace:"
			exception.backtrace.each do |b|
				puts b
			end
			Glyph.debug_mode = false
		end
	end
	false
end
