require 'asciidoctor/templates_compiler/ruby_beautify'
require 'corefines'

using Corefines::String::indent

module Asciidoctor::TemplatesCompiler
  describe RubyBeautify do
    include described_class

    describe '.call' do
      it 'is alias for .pretty_string' do
        expect( described_class.method(:call) )
          .to eq described_class.method(:pretty_string)
      end
    end


    describe '.pretty_string' do

      it 'indents code without semicolons' do
        expect( pretty_string <<~EOF
          class Foo
          def hi
          puts "Hello!"
          end
          end
        EOF
        ).to eq <<~EOF
          class Foo
            def hi
              puts "Hello!"
            end
          end
        EOF
      end

      it 'removes leading semicolons' do
        input = %(; _buf = ''\n;_buf << '<a' \n ; _buf << ' href='\n)
        expect( pretty_string(input) )
          .to eq input.gsub(/^[ \t]*;[ \t]*/, '')
      end

      it 'removes trailing semicolons' do
        input = %(_buf = '';\n_buf << '<a'; \n_buf << ' href=';\n)
        expect( pretty_string(input) )
          .to eq input.gsub(/;\s*$/, '')
      end

      it 'replaces in-between semicolons with newlines and indents' do
        expect( pretty_string <<~EOF
          _buf = ''; if true
          _buf << '<kbd>'; else; _buf << '<kbd id="key">'; end; _buf
        EOF
        ).to eq <<~EOF
          _buf = ''
          if true
            _buf << '<kbd>'
          else
            _buf << '<kbd id="key">'
          end
          _buf
        EOF
      end
    end
  end
end
