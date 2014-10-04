# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "glyph"
  s.version = "0.5.3"
  s.summary = "Glyph -- A Ruby-powered Document Authoring Framework"
  s.description = "Glyph is a framework for structured document authoring."
  s.homepage = "http://www.h3rald.com/glyph/"
  s.authors = ["Fabio Cevasco"]
  s.email = "h3rald@h3rald.com"
  s.date = "2012-11-10"
  s.license = "MIT"

  s.files = ["Rakefile"]
  s.files += Dir.glob("*.*")
  s.files += Dir.glob "bin/**/*"
  s.files += Dir.glob "lib/**/*"
  s.files += Dir.glob "book/*.*"
  s.files += Dir.glob "book/lib/**/*"
  s.files += Dir.glob "book/images/**/*"
  s.files += Dir.glob "book/text/**/*"
  s.files += Dir.glob "book/resources/**/*"
  s.files += Dir.glob "layouts/**/*"
  s.files += Dir.glob "macros/**/*"
  s.files += Dir.glob "spec/**/*"
  s.files += Dir.glob "styles/**/*"
  s.files += Dir.glob "tasks/**/*"

  s.require_paths = ["lib"]
  s.test_files = Dir.glob "spec/**/*"
  s.executables = ["glyph"]
  s.default_executable = "glyph"
  s.extra_rdoc_files = Dir.glob "*.textile"
 
  s.add_runtime_dependency("gli", [">= 2.4.1"])
  s.add_runtime_dependency("extlib", [">= 0.9.15"])
  s.add_runtime_dependency("rake", [">= 0.9.2.2"])

  s.add_development_dependency("rspec", [">= 2.11.0"])
  s.add_development_dependency("yard", [">= 0.8.3"])
  s.add_development_dependency("directory_watcher", [">= 1.4.1"])
  s.add_development_dependency("sass", [">= 3.2.1"])
  s.add_development_dependency("RedCloth", [">= 4.2.9"])
  s.add_development_dependency("bluecloth", [">= 2.2.0"])
  s.add_development_dependency("coderay", [">= 1.0.8"])
end
