require File.expand_path('../lib/asciidoctor/templates_compiler/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = 'asciidoctor-templates-compiler'
  s.version       = Asciidoctor::TemplatesCompiler::VERSION
  s.author        = 'Jakub Jirutka'
  s.email         = 'jakub@jirutka.cz'
  s.homepage      = 'https://github.com/jirutka/asciidoctor-templates-compiler'
  s.license       = 'MIT'

  s.summary       = 'Compile templates-based Asciidoctor converter (backend) into a single Ruby file'

  s.files         = Dir['lib/**', '*.gemspec', 'LICENSE*', 'README*']
end
