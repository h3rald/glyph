spec = Gem::Specification.new do |s| 
  s.name = 'glyph'
  s.version = '0.1.0'
  s.author = 'Fabio Cevasco'
  s.email = 'h3rald@h3rald.com'
  s.homepage = 'http://www.h3rald.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A Ruby-powered (Un)structured Document Authoring Framework'
  s.files = %w(bin/glyph)
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'glyph'
end
