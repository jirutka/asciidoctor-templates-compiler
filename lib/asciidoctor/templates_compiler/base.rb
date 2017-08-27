# frozen_string_literal: true
require 'asciidoctor/templates_compiler/version'
require 'asciidoctor/templates_compiler/converter_generator'
require 'asciidoctor/templates_compiler/ruby_beautify'
require 'stringio'

module Asciidoctor::TemplatesCompiler
  class Base
    class << self
      def compile_converter(**opts)
        new.compile_converter(**opts)
      end

      alias call compile_converter
    end

    def compile_converter(output: StringIO.new, templates_dir:, pretty: false, **opts)
      unless Dir.exist? templates_dir
        raise "Templates directory '#{templates_dir}' does not exist"
      end

      backend_info = opts[:backend_info] || {}
      templates = find_templates(templates_dir)
      transforms_code = compile_templates(templates, backend_info: backend_info, pretty: pretty)

      generate_class(output: output, transforms_code: transforms_code,
                     helpers_code: read_helpers(templates_dir), **opts)
    end

    alias call compile_converter

    protected

    # @abstract
    def compile_template(filename, backend_info: {})
    end

    # @abstract
    def find_templates(dirname)
    end

    def beautify_code(code, **opts)
      RubyBeautify.call(code, **opts)
    end

    def compile_templates(template_files, backend_info: {}, pretty: false)
      template_files.lazy.map do |path|
        code = compile_template(path, backend_info: backend_info)
        code = beautify_code(code) if pretty

        [transform_name_from_tmpl_name(path), code]
      end
    end

    def generate_class(**opts)
      ConverterGenerator.call(**opts)
    end

    def read_helpers(templates_dir)
      path = File.join(templates_dir, 'helpers.rb')
      IO.read(path) if File.exist? path
    end

    def transform_name_from_tmpl_name(filename)
      File.basename(filename)
        .sub(/\..*$/, '')
        .sub(/^block_/, '')
    end
  end
end
