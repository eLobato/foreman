module ComputeResourcesControllerTest
  extend ActiveSupport::Concern
  included do
    def setup
      Fog.mock!
    end

    def teardown
      Fog.unmock!
    end

    valid_attrs = { :name => 'special_compute', :provider => 'EC2', :region => 'eu-west-1', :user => 'user@example.com', :password => 'secret' }

    test "should get index" do
      get :index, { }
      assert_response :success
      assert_not_nil assigns(:compute_resources)
      compute_resources = ActiveSupport::JSON.decode(@response.body)
      assert !compute_resources.empty?
    end

    test "should show compute_resource" do
      get :show, { :id => compute_resources(:one).to_param }
      assert_response :success
      show_response = ActiveSupport::JSON.decode(@response.body)
      assert !show_response.empty?
    end

    test "should create valid compute resource" do
      post :create, { :compute_resource => valid_attrs }
      assert_response :created
      show_response = ActiveSupport::JSON.decode(@response.body)
      assert !show_response.empty?
    end

    test "should update compute resource" do
      put :update, { :id => compute_resources(:mycompute).to_param, :compute_resource => { :description => "new_description" } }
      assert_equal "new_description", ComputeResource.find_by_name('mycompute').description
      assert_response :success
    end

    test "should destroy compute resource" do
      assert_difference('ComputeResource.count', -1) do
        delete :destroy, { :id => compute_resources(:yourcompute).id }
      end
      assert_response :success
    end

    test "should allow access to a compute resource for owner" do
      setup_user 'view', 'compute_resources', "id = #{compute_resources(:mycompute).id}"
      get :show, { :id => compute_resources(:mycompute).to_param }
      assert_response :success
    end

    test "should update compute resource for owner" do
      setup_user 'edit', 'compute_resources', "id = #{compute_resources(:mycompute).id}"
      put :update, { :id => compute_resources(:mycompute).to_param, :compute_resource => { :description => "new_description" } }
      assert_equal "new_description", ComputeResource.find_by_name('mycompute').description
      assert_response :success
    end

    test "should destroy compute resource for owner" do
      assert_difference('ComputeResource.count', -1) do
        setup_user 'destroy', 'compute_resources', "id = #{compute_resources(:mycompute).id}"
        delete :destroy, { :id => compute_resources(:mycompute).id }
      end
      assert_response :success
    end

    test "should not allow access to a compute resource out of users compute resources scope" do
      setup_user 'view', 'compute_resources', "id = #{compute_resources(:mycompute).id}"
      get :show, { :id => compute_resources(:one).to_param }
      assert_response :not_found
    end

    test "should not update compute resource for restricted" do
      setup_user 'edit', 'compute_resources', "id = #{compute_resources(:mycompute).id}"
      put :update, { :id => compute_resources(:yourcompute).to_param, :compute_resource => { :description => "new_description" } }
      assert_response :not_found
    end

    test "should not destroy compute resource for restricted" do
      setup_user 'destroy', 'compute_resources', "id = #{compute_resources(:mycompute).id}"
      delete :destroy, { :id => compute_resources(:yourcompute).id }
      assert_response :not_found
    end

    test "should update boolean attribute set_console_password for Libvirt compute resource" do
      cr = compute_resources(:one)
      put :update, { :id => cr.id, :compute_resource => { :set_console_password => true } }
      cr.reload
      assert_equal 1, cr.attrs[:setpw]
    end

    test "should update boolean attribute set_console_password for VMware compute resource" do
      cr = compute_resources(:vmware)
      put :update, { :id => cr.id, :compute_resource => { :set_console_password => true } }
      cr.reload
      assert_equal 1, cr.attrs[:setpw]
    end

    test "should not update set_console_password to true for non-VMware or non-Libvirt compute resource" do
      cr = compute_resources(:openstack)
      put :update, { :id => cr.id, :compute_resource => { :set_console_password => true } }
      cr.reload
      assert_nil cr.attrs[:setpw]
    end
  end
end
