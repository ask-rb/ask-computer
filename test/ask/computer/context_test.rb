# frozen_string_literal: true

require_relative "../../test_helper"

class ContextTest < Minitest::Test
  def test_context_constants
    assert Ask::Computer::DESCRIPTION.is_a?(String)
    assert Ask::Computer::DOCS_URL.start_with?("https://")
    assert Ask::Computer::QUICK_START.include?("Ask::Computer")
  end
end
