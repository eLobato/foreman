require 'test_helper'
require_relative '../shared/hosts_controller_test'

class Api::V1::HostsControllerTest < ActionController::TestCase
  include ::HostsControllerTest

  def valid_attrs
    { :name                => 'testhost11',
      :environment_id      => environments(:production).id,
      :domain_id           => domains(:mydomain).id,
      :ip                  => '10.0.0.20',
      :mac                 => '52:53:00:1e:85:93',
      :ptable_id           => @ptable.id,
      :medium_id           => media(:one).id,
      :architecture_id     => Architecture.find_by_name('x86_64').id,
      :operatingsystem_id  => Operatingsystem.find_by_name('Redhat').id,
      :puppet_proxy_id     => smart_proxies(:one).id,
      :compute_resource_id => compute_resources(:one).id,
      :root_pass           => "xybxa6JUkz63w",
      :location_id         => taxonomies(:location1).id,
      :organization_id     => taxonomies(:organization1).id
    }
  end

  test "should create host" do
    disable_orchestration
    assert_difference('Host.count') do
      post :create, { :host => valid_attrs }
    end
    assert_response :success
  end

  test "should update host" do
    put :update, { :id => @host.to_param, :host => { :name => 'testhost1435' } }
    assert_response :success
  end

  test "should be able to create hosts even when restricted" do
    disable_orchestration
    assert_difference('Host.count') do
      post :create, { :host => valid_attrs }
    end
    assert_response :success
  end

  test "should not list a host out of users hosts scope" do
    host = FactoryGirl.create(:host, :owner => users(:restricted))
    setup_user 'view', 'hosts', "owner_type = User and owner_id = #{users(:restricted).id}", :restricted
    get :index, {}
    assert_response :success
    hosts = ActiveSupport::JSON.decode(@response.body)
    ids = hosts.map { |hash| hash['host']['id'] }
    refute_includes ids, @host.id
    assert_includes ids, host.id
  end
end
