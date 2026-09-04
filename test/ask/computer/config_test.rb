# frozen_string_literal: true

require_relative "../../test_helper"

class ConfigTest < Minitest::Test
  def test_defaults
    config = Ask::Computer::Config.new
    assert_equal "cua-driver", config.driver_command
    assert_equal ["mcp"], config.driver_args
    assert_equal 50, config.history_default_limit
    assert_equal :stdio, config.transport
  end

  def test_configure_and_reset
    Ask::Computer.configure { |c| c.driver_command = "custom-driver" }
    assert_equal "custom-driver", Ask::Computer.config.driver_command
  ensure
    Ask::Computer.reset!
    assert_equal "cua-driver", Ask::Computer.config.driver_command
  end

  def test_driver_url_predicate
    config = Ask::Computer::Config.new
    refute config.driver_url?
    config.driver_url = "http://localhost:3000"
    assert config.driver_url?
  end

  def test_driver_args_env_override
    ENV["ASK_COMPUTER_DRIVER_ARGS"] = "mcp --verbose"
    config = Ask::Computer::Config.new
    assert_equal ["mcp", "--verbose"], config.driver_args
  ensure
    ENV.delete("ASK_COMPUTER_DRIVER_ARGS")
  end
end
