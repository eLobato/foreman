require 'test_helper'
require_relative '../shared/subnets_controller_test'

class Api::V2::SubnetsControllerTest < ActionController::TestCase
  include ::SubnetsControllerTest

  test "index content is a JSON array" do
    get :index
    subnets = ActiveSupport::JSON.decode(@response.body)
    assert subnets['results'].is_a?(Array)
    assert_response :success
    assert !subnets.empty?
  end
end
