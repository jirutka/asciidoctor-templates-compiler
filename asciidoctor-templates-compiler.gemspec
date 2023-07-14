require File.expand_path('../lib/asciidoctor/templates_compiler/version', __FILE__)

Gem::Specification.new do |s|
  s.name     = 'asciidoctor-templates-compiler'
  s.version  = Asciidoctor::TemplatesCompiler::VERSION
  s.author   = 'Jakub Jirutka'
  s.email    = 'jakub@jirutka.cz'
  s.homepage = 'https://github.com/jirutka/asciidoctor-templates-compiler'
  s.license  = 'MIT'

  s.summary  = 'Compile templates-based Asciidoctor converter (backend) into a single Ruby file'

  s.files    = Dir['lib/**/*', '*.gemspec', 'LICENSE*', 'README*']
  s.executables = Dir['bin/*'].map { |f| File.basename(f) }

  s.required_ruby_version = '>= 2.1'

  s.add_runtime_dependency 'asciidoctor', '~> 2.0'
  s.add_runtime_dependency 'corefines', '~> 1.2'
  s.add_runtime_dependency 'docopt', '~> 0.6'
  s.add_runtime_dependency 'slim', '>= 2.1', '< 6.0'
  s.add_runtime_dependency 'ruby-beautify2', '~> 0.98'

  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rspec', '~> 3.6'
  s.add_development_dependency 'rubocop', '~> 0.49.0'
  s.add_development_dependency 'simplecov', '~> 0.14'
end
