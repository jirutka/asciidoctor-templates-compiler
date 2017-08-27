# frozen_string_literal: true
require 'asciidoctor/converter'
require 'asciidoctor/converter/template'
require 'asciidoctor/templates_compiler/version'
require 'asciidoctor/templates_compiler/base'
require 'corefines'
require 'slim'
require 'slim/include'

module Asciidoctor::TemplatesCompiler
  class Slim < Base
    using Corefines::Object::then

    protected

    def compile_template(filename, backend_info: {})
      htmlsyntax = backend_info[:htmlsyntax] || backend_info['htmlsyntax'] || :html
      opts = engine_options.merge(file: filename, format: htmlsyntax.to_sym)
      content = IO.read(filename)

      ::Slim::Engine.new(opts).call(content).tap do |code|
        code.scan(/::(?:Slim|Temple)(?:\:\:\w+)*/).uniq.each do |name|
          $stderr.puts "WARNING: Compiled template '#{filename}' references constant #{name}"
        end
      end
    end

    def find_templates(dirname)
      Dir.glob("#{dirname}/[^_]*.slim")
    end

    def read_helpers(templates_dir)
      super.then { |s| s.sub('module Slim::Helpers', 'module Helpers') }
    end

    def engine_options
      ::Asciidoctor::Converter::TemplateConverter::DEFAULT_ENGINE_OPTIONS[:slim]
    end
  end
end
