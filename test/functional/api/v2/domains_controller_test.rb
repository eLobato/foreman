require 'test_helper'
require_relative '../shared/domains_controller_test'

class Api::V2::DomainsControllerTest < ActionController::TestCase
  include ::DomainsControllerTest

  def setup
    taxonomies(:location1).domain_ids = [domains(:mydomain).id, domains(:yourdomain).id]
    taxonomies(:organization1).domain_ids = [domains(:mydomain).id]
  end

  test "should get domains for location only" do
    get :index, {:location_id => taxonomies(:location1).id }
    assert_response :success
    assert_equal 2, assigns(:domains).length
    assert_equal assigns(:domains), [domains(:mydomain), domains(:yourdomain)]
  end

  test "should get domains for organization only" do
    get :index, {:organization_id => taxonomies(:organization1).id }
    assert_response :success
    assert_equal 1, assigns(:domains).length
    assert_equal assigns(:domains), [domains(:mydomain)]
  end

  test "should get domains for both location and organization" do
    get :index, {:location_id => taxonomies(:location1).id, :organization_id => taxonomies(:organization1).id }
    assert_response :success
    assert_equal 1, assigns(:domains).length
    assert_equal assigns(:domains), [domains(:mydomain)]
  end

  test "should show domain with correct child nodes including location and organization" do
    get :show, { :id => domains(:mydomain).to_param }
    assert_response :success
    show_response = ActiveSupport::JSON.decode(@response.body)
    assert !show_response.empty?
    #assert child nodes are included in response'
    NODES = ["locations", "organizations", "parameters", "subnets"]
    NODES.sort.each do |node|
      assert show_response.keys.include?(node), "'#{node}' child node should be in response but was not"
    end
  end
end
