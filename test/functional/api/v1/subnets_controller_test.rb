require 'test_helper'
require_relative '../shared/subnets_controller_test'

class Api::V1::SubnetsControllerTest < ActionController::TestCase
  include ::SubnetsControllerTest
  valid_attrs = { :name => 'QA2', :network => '10.35.2.27', :mask => '255.255.255.0' }

  def test_index
    get :index
    subnets = ActiveSupport::JSON.decode(@response.body)
    assert subnets.is_a?(Array)
    assert_response :success
    assert !subnets.empty?
  end
end
