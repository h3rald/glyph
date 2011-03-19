# encoding: utf-8

include GLI

GLI.desc "Enable debugging"
switch [:d, :debug]

require Glyph::LIB/'commands/init'
require Glyph::LIB/'commands/add'
require Glyph::LIB/'commands/compile'
require Glyph::LIB/'commands/config'
require Glyph::LIB/'commands/todo'
require Glyph::LIB/'commands/outline'
require Glyph::LIB/'commands/stats'

Glyph.run 'load:tasks'
Glyph.run 'load:commands'

version Glyph::VERSION

pre do |global,command,options,args|
	# Pre logic here
	# Return true to proceed; false to abourt and not call the
	# chosen command
	if global[:d] then
		Glyph.debug_mode = true
	end
	if !command || command.name == :help then
		puts "====================================="
		puts "Glyph v#{Glyph::VERSION}"
		puts "====================================="
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
