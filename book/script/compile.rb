require 'pathname'
require 'extlib'
require Pathname.new(__FILE__).parent.parent.parent/"lib/glyph.rb"
require 'glyph/commands'

puts Dir.pwd

GLI.run ["compile"]
