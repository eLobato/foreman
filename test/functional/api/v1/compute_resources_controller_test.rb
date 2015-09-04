require 'test_helper'
require_relative '../shared/compute_resources_controller_test'

class Api::V1::ComputeResourcesControllerTest < ActionController::TestCase
  include ::ComputeResourcesControllerTest

  test "should get index of owned" do
    setup_user 'view', 'compute_resources', "id = #{compute_resources(:mycompute).id}"
    get :index, {}
    assert_response :success
    assert_not_nil assigns(:compute_resources)
    compute_resources = ActiveSupport::JSON.decode(@response.body)
    ids               = compute_resources.map { |hash| hash['compute_resource']['id'] }
    assert_includes ids, compute_resources(:mycompute).id
    refute_includes ids, compute_resources(:yourcompute).id
  end
end
