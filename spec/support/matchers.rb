require 'rspec/expectations'

RSpec::Matchers.define :be_valid_ruby do
  description do
    'be a valid Ruby code'
  end

  match do |code|
    begin
      check_syntax! code
      true
    rescue SyntaxError
      false
    end
  end

  failure_message do |code|
    begin
      check_syntax! code
    rescue SyntaxError => e
      e.message
    end
  end

  # See https://www.ruby-forum.com/topic/4419079#1130079
  def check_syntax!(code)
    catch(:good) do
      eval("BEGIN { throw :good }; #{code}")  # rubocop:disable Security/Eval
    end
  end
end
