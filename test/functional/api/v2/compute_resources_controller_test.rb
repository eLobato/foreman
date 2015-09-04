require 'test_helper'
require_relative '../shared/compute_resources_controller_test'

class Api::V2::ComputeResourcesControllerTest < ActionController::TestCase
  include ::ComputeResourcesControllerTest

  test "should get index of owned" do
    setup_user 'view', 'compute_resources', "id = #{compute_resources(:mycompute).id}"
    get :index, {}
    assert_response :success
    assert_not_nil assigns(:compute_resources)
    compute_resources = ActiveSupport::JSON.decode(@response.body)
    ids               = compute_resources['results'].map { |hash| hash['id'] }
    assert_includes ids, compute_resources(:mycompute).id
    refute_includes ids, compute_resources(:yourcompute).id
  end

  test "should get specific vmware storage domain" do
    storage_domain = Object.new
    storage_domain.stubs(:name).returns('test_vmware_cluster')
    storage_domain.stubs(:id).returns('my11-test35-uuid99')

    Foreman::Model::Vmware.any_instance.expects(:available_storage_domains).with('test_vmware_cluster').returns([storage_domain])

    get :available_storage_domains, { :id => compute_resources(:vmware).to_param, :storage_domain => 'test_vmware_cluster' }
    assert_response :success
    available_storage_domains = ActiveSupport::JSON.decode(@response.body)
    assert_equal storage_domain.id, available_storage_domains['results'].first.try(:[], 'id')
  end

  test "should associate hosts that match" do
    host_cr = FactoryGirl.create(:host, :on_compute_resource)
    host_bm = FactoryGirl.create(:host)

    uuid = Foreman.uuid
    vm2 = mock('vm2')
    vm2.expects(:identity).at_least_once.returns(uuid)
    vms = [mock('vm1', :identity => host_cr.uuid), vm2]
    ComputeResource.any_instance.expects(:vms).returns(vms)

    Foreman::Model::EC2.any_instance.expects(:associated_host).returns(host_bm)
    put :associate, { :id => host_cr.compute_resource.to_param }
    assert_response :success

    hosts = ActiveSupport::JSON.decode(@response.body)
    assert_equal [host_bm.id], hosts['results'].map { |h| h['id'] }
    assert_equal uuid, host_bm.reload.uuid
    assert_equal host_cr.compute_resource.id, host_bm.compute_resource_id
    assert host_bm.compute?
  end


  test "should get available images" do
    img = Object.new
    img.stubs(:name).returns('some_image')
    img.stubs(:id).returns('123')

    Foreman::Model::EC2.any_instance.stubs(:available_images).returns([img])

    get :available_images, { :id => compute_resources(:ec2).to_param }
    assert_response :success
    available_images = ActiveSupport::JSON.decode(@response.body)
    assert_not_empty available_images
  end

  test "should get available networks" do
    network = Object.new
    network.stubs(:name).returns('test_network')
    network.stubs(:id).returns('my11-test35-uuid99')

    Foreman::Model::Ovirt.any_instance.stubs(:available_networks).returns([network])

    get :available_networks, { :id => compute_resources(:ovirt).to_param, :cluster_id => '123-456-789' }
    assert_response :success
    available_networks = ActiveSupport::JSON.decode(@response.body)
    assert !available_networks.empty?
  end

  test "should get available clusters" do
    cluster = Object.new
    cluster.stubs(:name).returns('test_cluster')
    cluster.stubs(:id).returns('my11-test35-uuid99')

    Foreman::Model::Ovirt.any_instance.stubs(:available_clusters).returns([cluster])

    get :available_clusters, { :id => compute_resources(:ovirt).to_param }
    assert_response :success
    available_clusters = ActiveSupport::JSON.decode(@response.body)
    assert !available_clusters.empty?
  end

  test "should get available storage domains" do
    storage_domain = Object.new
    storage_domain.stubs(:name).returns('test_cluster')
    storage_domain.stubs(:id).returns('my11-test35-uuid99')

    Foreman::Model::Ovirt.any_instance.stubs(:available_storage_domains).returns([storage_domain])

    get :available_storage_domains, { :id => compute_resources(:ovirt).to_param }
    assert_response :success
    available_storage_domains = ActiveSupport::JSON.decode(@response.body)
    assert !available_storage_domains.empty?
  end

  context 'vmware' do
    setup do
      @vmware_object = Object.new
      @vmware_object.stubs(:name).returns('test_vmware_object')
      @vmware_object.stubs(:id).returns('my11-test35-uuid99')
    end

    teardown do
      assert_response :success
      available_objects = ActiveSupport::JSON.decode(@response.body)
      assert_not_empty available_objects
    end

    test "should get available vmware networks" do
      Foreman::Model::Vmware.any_instance.stubs(:available_networks).returns([@vmware_object])
      get :available_networks, { :id => compute_resources(:vmware).to_param, :cluster_id => '123-456-789' }
    end

    test "should get available vmware clusters" do
      Foreman::Model::Vmware.any_instance.stubs(:available_clusters).returns([@vmware_object])
      get :available_clusters, { :id => compute_resources(:vmware).to_param }
    end

    test "should get available vmware storage domains" do
      Foreman::Model::Vmware.any_instance.stubs(:available_storage_domains).returns([@vmware_object])
      get :available_storage_domains, { :id => compute_resources(:vmware).to_param }
    end

    test "should get available vmware resource pools" do
      Foreman::Model::Vmware.any_instance.stubs(:available_resource_pools).returns([@vmware_object])
      get :available_resource_pools, { :id => compute_resources(:vmware).to_param, :cluster_id => '123-456-789' }
    end

    test "should get available vmware folders" do
      Foreman::Model::Vmware.any_instance.stubs(:available_folders).returns([@vmware_object])
      get :available_folders, { :id => compute_resources(:vmware).to_param, :cluster_id => '123-456-789' }
    end
  end
end
