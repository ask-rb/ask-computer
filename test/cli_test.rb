# frozen_string_literal: true

require_relative "test_helper"
require "ask/computer/cli"

class CliTest < Minitest::Test
  def test_help
    assert_equal 0, Ask::Computer::CLI.run(["help"])
    assert_equal 0, Ask::Computer::CLI.run([])
    assert_equal 0, Ask::Computer::CLI.run(["--help"])
  end

  def test_install_dry_run
    assert_equal 0, Ask::Computer::CLI.run(["install", "--dry-run"])
    assert_equal 0, Ask::Computer::CLI.run(["install", "--channel", "nightly", "--dry-run"])
  end

  def test_unknown_command_shows_help_and_returns_nonzero
    assert_equal 1, Ask::Computer::CLI.run(["unknown-command-xyz"])
  end
end
