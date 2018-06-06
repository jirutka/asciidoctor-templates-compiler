# frozen_string_literal: true
require 'asciidoctor'
require 'asciidoctor/converter'
require 'asciidoctor/converter/template'
require 'asciidoctor/templates_compiler/version'
require 'asciidoctor/templates_compiler/base'
require 'asciidoctor/templates_compiler/temple_ext'
require 'corefines'
require 'slim'
require 'slim/include'

module Asciidoctor::TemplatesCompiler
  class Slim < Base

    DEFAULT_ENGINE_OPTS =
      ::Asciidoctor::Converter::TemplateConverter::DEFAULT_ENGINE_OPTIONS[:slim].dup.freeze

    def compile_converter(backend_info: {}, engine_opts: {}, **)
      engine_opts[:format] ||= backend_info.fetch('htmlsyntax', 'html').to_sym
      super
    end

    protected

    def compile_template(filename, engine_opts = {})
      engine_opts = DEFAULT_ENGINE_OPTS.merge(**engine_opts, file: filename)
      content = IO.read(filename)

      ::Slim::Engine.new(engine_opts).call(content).tap do |code|
        code.scan(/::(?:Slim|Temple)(?:\:\:\w+)*/).uniq.each do |name|
          $stderr.puts "WARNING: Compiled template '#{filename}' references constant #{name}"
        end
      end
    end

    def find_templates(dirname)
      Dir.glob("#{dirname}/[^_]*.slim")
    end

    def read_helpers(templates_dir)
      super.sub('module Slim::Helpers', 'module Helpers')
    end
  end
end
