require 'test_helper'

class CustomRunnerTest < ActiveSupport::TestCase
  test "custom runner is working" do
    skip "Temporarily disabled until we figure out a way to skip tests without Minitest Runner API"
    # This should always be skipped if the runner is working
    assert false, "Custom runner has failed"
  end
end
