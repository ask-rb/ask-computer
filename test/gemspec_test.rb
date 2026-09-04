# frozen_string_literal: true

require_relative "test_helper"

class GemspecTest < Minitest::Test
  def test_gemspec_is_valid
    spec = Gem::Specification.load(File.expand_path("../ask-computer.gemspec", __dir__))
    assert spec, "Could not load gemspec"
    assert_kind_of Gem::Specification, spec
    assert_equal "ask-computer", spec.name
    assert spec.version.to_s > "0"
  end

  def test_gemspec_files_include_skill
    spec = Gem::Specification.load(File.expand_path("../ask-computer.gemspec", __dir__))
    assert_includes spec.files, "lib/ask/skills/computer.use_computer/SKILL.md"
    assert_includes spec.files, "lib/ask/skills/computer.use_computer/references/history.md"
  end
end
