# frozen_string_literal: true
require 'asciidoctor/templates_compiler/version'
require 'asciidoctor/templates_compiler/string_ext'
require 'corefines'
require 'stringio'

module Asciidoctor::TemplatesCompiler
  ##
  # Source-code generator of Asciidoctor converter classes.
  class ConverterGenerator
    using Corefines::String[:indent, :unindent]
    using Corefines::Object::blank?
    using StringExt::reindent

    class << self
      ##
      # (see #initialize)
      # @param output [#<<] output stream where to write the generated class.
      #   Defaults to {StringIO}.
      # @return the given _output_ stream.
      #
      def generate(output: StringIO.new, **opts)
        new(**opts).call(output)
      end

      # An alias for {.generate}.
      alias call generate
    end

    ##
    # @param class_name [String] full name of the converter class to generate
    #   (e.g. +My::HTML::Converter+).
    # @param transforms_code [#each] enumerable that yields pair: transform name ()
    # @param helpers_code [String, nil] source code to include in the generated class. It must
    #   contain a module named +Helpers+.
    # @param register_for [Array<String>] an array of backend names that the generated converter
    #   should be registered for to handle. Default is empty.
    # @param backend_info [Hash] a hash of parameters for +backend_info+: +basebackend+,
    #   +outfilesuffix+, +filetype+, +htmlsyntax+, +supports_templates+. Default is empty.
    # @param delegate_backend [String, nil] name of the backend (converter) to use as a fallback
    #   for AST nodes not supported by the generated converter. If not specified, no fallback will
    #   be used and converter will raise +NoMethodError+ when it try to convert unsupported node.
    #
    # @raise [ArgumentError] if _helpers_code_ is not blank and does not contain module +Helpers+.
    #
    def initialize(class_name:, transforms_code:, helpers_code: nil,
                   register_for: [], backend_info: {}, delegate_backend: nil, **)
      @class_name = class_name
      @transforms_code = transforms_code
      @helpers_code = helpers_code
      @register_for = Array(register_for)
      @backend_info = backend_info
      @delegate_backend = delegate_backend

      if !helpers_code.blank? && helpers_code !~ /\bmodule Helpers[\s#]/
        raise ArgumentError, 'The helpers_code does not contain module Helpers'
      end
    end

    ##
    # Generates source code of a converter class for Asciidoctor.
    #
    # @param out [#<<] output stream where to write the generated class.
    # @return the given _out_ stream.
    #
    def generate(out = StringIO.new)
      out << head_code << "\n"
      out << helpers_code << "\n" unless @helpers_code.blank?
      out << initialization_code << "\n"
      out << convert_method_code << "\n"
      transform_methods_code(out)
      out << support_methods_code << "\n"
      out << tail_code
      out
    end

    alias call generate

    protected

    def head_code
      init_modules = @class_name
        .split('::')[0..-2]
        .map { |name| "module #{name};" }
        .tap { |ary| ary.push('end ' * ary.size) }
        .join(' ').strip

      <<-EOF.unindent
        # This file has been generated!

        #{init_modules}
        class #{@class_name} < ::Asciidoctor::Converter::Base
      EOF
    end

    def helpers_code
      <<-EOF.unindent.%(@helpers_code).indent(2)
        #{separator 'Begin of Helpers'}
        %s

        # Make Helpers' constants accessible from transform methods.
        Helpers.constants.each do |const|
          const_set(const, Helpers.const_get(const))
        end

        #{separator 'End of Helpers'}
      EOF
    end

    def initialization_code
      setup_backend_info = if !@backend_info.empty?
        @backend_info.map { |key, value|
          "  #{key}" + (value == true ? '' : " #{value.inspect}")
        }.join("\n")
      end

      if !@register_for.empty?
        register_for = "register_for #{@register_for.map(&:inspect).join(', ')}\n"
      end

      if @delegate_backend
        delegate_converter = <<-EOF.reindent(2).rstrip

          delegate_backend = (opts[:delegate_backend] || #{@delegate_backend.inspect}).to_s
          factory = ::Asciidoctor::Converter::Factory

          converter = factory.create(delegate_backend, backend_info)
          @delegate_converter = if converter == self
            factory.new.create(delegate_backend, backend_info)
          else
            converter
          end
        EOF
      end

      [
        register_for,
        'def initialize(backend, opts = {})',
        '  super',
        setup_backend_info,
        delegate_converter,
        'end',
        '',
      ].compact.join("\n").indent(2)
    end

    def convert_method_code
      converter = if @delegate_backend
        'respond_to?(transform) ? self : @delegate_converter'
      else
        'self'
      end

      <<-EOF.reindent(2)
        def convert(node, transform = nil, opts = {})
          transform ||= node.node_name
          converter = #{converter}

          if opts.empty?
            converter.send(transform, node)
          else
            converter.send(transform, node, opts)
          end
        end
      EOF
    end

    def support_methods_code
      <<-EOF.reindent(2)
        def set_local_variables(binding, vars)
          vars.each do |key, val|
            binding.local_variable_set(key.to_sym, val)
          end
        end
      EOF
    end

    def transform_methods_code(out)
      out << "  #{separator 'Begin of generated transformation methods'}\n"

      @transforms_code.each do |name, code|
        out << "\n"
        out << "  def #{name}(node, opts = {})\n"
        out << "    node.extend(Helpers)\n" unless @helpers_code.blank?
        out << "    node.instance_eval do\n"
        out << "      converter.set_local_variables(binding, opts) unless opts.empty?\n"
        out << code.indent(6, ' ') << "\n"
        out << "    end\n"
        out << "  end\n"
      end

      out << "  #{separator 'End of generated transformation methods'}\n"
    end

    def tail_code
      "end\n"
    end

    private

    def separator(title)
      dashes = '-' * ((76 - title.length) / 2)
      "##{dashes} #{title} #{dashes}#\n"
    end
  end
end
