# frozen_string_literal: true

require_relative "test_helper"

class SkillTest < Minitest::Test
  def test_skill_file_exists
    path = File.expand_path("../lib/ask/skills/computer.use_computer/SKILL.md", __dir__)
    assert File.exist?(path), "SKILL.md missing at #{path}"
    content = File.read(path)
    assert_includes content, "name: computer.use_computer"
    assert_includes content, "Cua Driver"
  end

  def test_history_reference_exists
    path = File.expand_path("../lib/ask/skills/computer.use_computer/references/history.md", __dir__)
    assert File.exist?(path)
    assert_includes File.read(path), "Status Response"
  end

  def test_skill_discoverable_via_gem_find_files
    found = Gem.find_files("ask/skills/*/SKILL.md")
    assert found.any? { |p| p.include?("computer.use_computer") }, "computer.use_computer not found via Gem.find_files. Run bundle install?"
  end
end
