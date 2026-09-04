# frozen_string_literal: true

require_relative "../../test_helper"

class VersionTest < Minitest::Test
  def test_version_is_string
    assert_kind_of String, Ask::Computer::VERSION
    assert_match(/\A\d+\.\d+\.\d+/, Ask::Computer::VERSION)
  end
end
