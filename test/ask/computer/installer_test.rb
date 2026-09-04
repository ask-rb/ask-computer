# frozen_string_literal: true

require_relative "../../test_helper"

class InstallerTest < Minitest::Test
  def test_install_dry_run_does_not_execute
    result = Ask::Computer::Installer.install(channel: "nightly", dry_run: true)
    assert result.ok?
    assert_includes result.command, "nightly"
    assert_includes result.command, "https://cua.ai/driver/install.sh"
  end

  def test_setup_dry_run_when_not_installed
    Ask::Computer::Installer.stubs(:installed?).returns(false)
    Ask::Computer::Installer.stubs(:install).returns(
      Ask::Computer::Installer::Result.new(ok: true, command: "install", stdout: "", stderr: "", exit_code: 0, message: "ok")
    )
    steps = Ask::Computer::Installer.setup(channel: "stable", enable_history: false, dry_run: true)
    assert_equal 1, steps.size
    assert_equal :install, steps[0][0]
  ensure
    Ask::Computer::Installer.unstub(:installed?) rescue nil
    Ask::Computer::Installer.unstub(:install) rescue nil
  end

  def test_status_shape_when_not_installed
    # Stub which so installed? is false and version/history also stubbed
    Ask::Computer::Installer.stubs(:which).returns(nil)
    Open3.stubs(:capture3).returns(["", "not found", mock_status(false)])
    s = Ask::Computer::Installer.status
    assert_equal false, s[:installed]
    assert_nil s[:version]
    assert_nil s[:bin]
  ensure
    Ask::Computer::Installer.unstub(:which) rescue nil
    Open3.unstub(:capture3) rescue nil
  end

  def test_ask_computer_delegates
    assert_respond_to Ask::Computer, :install
    assert_respond_to Ask::Computer, :setup
    assert_respond_to Ask::Computer, :status
    assert_respond_to Ask::Computer, :installed?
    assert_equal Ask::Computer::Installer, Ask::Computer.installer
  end

  private

  def mock_status(success)
    s = mock("status")
    s.stubs(:success?).returns(success)
    s.stubs(:exitstatus).returns(success ? 0 : 1)
    s
  end
end
