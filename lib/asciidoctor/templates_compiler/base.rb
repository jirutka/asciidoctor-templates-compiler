# frozen_string_literal: true
require 'asciidoctor/templates_compiler/version'
require 'asciidoctor/templates_compiler/converter_generator'
require 'asciidoctor/templates_compiler/ruby_beautify'
require 'stringio'

module Asciidoctor::TemplatesCompiler
  ##
  # Base class for templates compilers.
  class Base
    class << self
      ##
      # An "alias" for {#compile_converter}.
      def compile_converter(**opts)
        new.compile_converter(**opts)
      end

      alias call compile_converter
    end

    ##
    # (see ConverterGenerator.generate)
    #
    # Compiles templates found in _templates_dir_ to Ruby and generates an Asciidoctor converter
    # class from them.
    #
    # @param templates_dir [String] path of the directory where to look for templates
    #   and (optional) +helpers.rb+.
    # @param engine_opts [Hash] a hash of options to pass into the templating engine.
    #   Default is empty.
    # @param pretty [Boolean] enable pretty-formatting of the generated Ruby code?
    #
    # @raise [ArgumentError] if the given _templates_dir_ does not exist.
    #
    def compile_converter(templates_dir:, engine_opts: {}, pretty: false, **opts)
      unless Dir.exist? templates_dir
        raise ArgumentError, "Templates directory '#{templates_dir}' does not exist"
      end

      templates = find_templates(templates_dir)
      transforms_code = compile_templates(templates, engine_opts, pretty: pretty)

      generate_class(transforms_code: transforms_code,
                     helpers_code: read_helpers(templates_dir), **opts)
    end

    alias call compile_converter

    protected

    ##
    # @abstract
    # @param filename [String] path of the template file to compile.
    # @param engine_opts [Hash] a hash of options to pass into the templating engine.
    # @return [String] a Ruby code of the compiled template.
    #
    def compile_template(filename, engine_opts = {})
    end

    ##
    # @abstract
    # @param dirname [String] path of the directory where to look for templates.
    # @return [Array<String>] paths of the found template files.
    #
    def find_templates(dirname)
    end

    def beautify_code(code, **opts)
      RubyBeautify.call(code, **opts)
    end

    def compile_templates(template_files, engine_opts = {}, pretty: false)
      template_files.lazy.map do |path|
        code = compile_template(path, engine_opts)
        code = beautify_code(code) if pretty

        [transform_name_from_tmpl_name(path), code]
      end
    end

    def generate_class(**opts)
      ConverterGenerator.call(**opts)
    end

    def read_helpers(templates_dir)
      path = File.join(templates_dir, 'helpers.rb')
      File.exist?(path) ? IO.read(path) : ''
    end

    def transform_name_from_tmpl_name(filename)
      File.basename(filename)
        .sub(/\..*$/, '')
        .sub(/^block_/, '')
    end
  end
end
