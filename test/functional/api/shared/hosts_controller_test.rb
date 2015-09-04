module HostsControllerTest
  extend ActiveSupport::Concern
  included do
    def setup
      @host = FactoryGirl.create(:host)
      @ptable = FactoryGirl.create(:ptable)
      @ptable.operatingsystems = [ Operatingsystem.find_by_name('Redhat') ]
    end

    test "should get index" do
      get :index, { }
      assert_response :success
      assert_not_nil assigns(:hosts)
      hosts = ActiveSupport::JSON.decode(@response.body)
      assert !hosts.empty?
    end

    test "should show individual record" do
      get :show, { :id => @host.to_param }
      assert_response :success
      show_response = ActiveSupport::JSON.decode(@response.body)
      assert !show_response.empty?
    end

    test "should create host with managed is false if parameter is passed" do
      disable_orchestration
      post :create, { :host => valid_attrs.merge!(:managed => false) }
      assert_response :created
      assert_equal false, Host.order('id desc').last.managed?
    end

    test "should destroy hosts" do
      assert_difference('Host.count', -1) do
        delete :destroy, { :id => @host.to_param }
      end
      assert_response :success
    end

    test "should show status hosts" do
      get :status, { :id => @host.to_param }
      assert_response :success
    end

    test "should allow access to restricted user who owns the host" do
      host = FactoryGirl.create(:host, :owner => users(:restricted))
      setup_user 'view', 'hosts', "owner_type = User and owner_id = #{users(:restricted).id}", :restricted
      get :show, { :id => host.to_param }
      assert_response :success
    end

    test "should allow to update for restricted user who owns the host" do
      disable_orchestration
      host = FactoryGirl.create(:host, :owner => users(:restricted))
      setup_user 'edit', 'hosts', "owner_type = User and owner_id = #{users(:restricted).id}", :restricted
      put :update, { :id => host.to_param, :host => valid_attrs }
      assert_response :success
    end

    test "should allow destroy for restricted user who owns the hosts" do
      host = FactoryGirl.create(:host, :owner => users(:restricted))
      assert_difference('Host.count', -1) do
        setup_user 'destroy', 'hosts', "owner_type = User and owner_id = #{users(:restricted).id}", :restricted
        delete :destroy, { :id => host.to_param }
      end
      assert_response :success
    end

    test "should allow show status for restricted user who owns the hosts" do
      host = FactoryGirl.create(:host, :owner => users(:restricted))
      setup_user 'view', 'hosts', "owner_type = User and owner_id = #{users(:restricted).id}", :restricted
      get :status, { :id => host.to_param }
      assert_response :success
    end

    test "should not allow access to a host out of users hosts scope" do
      setup_user 'view', 'hosts', "owner_type = User and owner_id = #{users(:restricted).id}", :restricted
      get :show, { :id => @host.to_param }
      assert_response :not_found
    end

    test "should not update host out of users hosts scope" do
      setup_user 'edit', 'hosts', "owner_type = User and owner_id = #{users(:restricted).id}", :restricted
      put :update, { :id => @host.to_param }
      assert_response :not_found
    end

    test "should not delete hosts out of users hosts scope" do
      setup_user 'destroy', 'hosts', "owner_type = User and owner_id = #{users(:restricted).id}", :restricted
      delete :destroy, { :id => @host.to_param }
      assert_response :not_found
    end

    test "should not show status of hosts out of users hosts scope" do
      setup_user 'view', 'hosts', "owner_type = User and owner_id = #{users(:restricted).id}", :restricted
      get :status, { :id => @host.to_param }
      assert_response :not_found
    end

    def set_remote_user_to(user)
      @request.env['REMOTE_USER'] = user.login
    end

    test "when REMOTE_USER is provided and both authorize_login_delegation{,_api}
        are set, authentication should succeed w/o valid session cookies" do
      Setting[:authorize_login_delegation] = true
      Setting[:authorize_login_delegation_api] = true
      set_remote_user_to users(:admin)
      User.current = nil # User.current is admin at this point (from initialize_host)
      host = Host.first
      get :show, {:id => host.to_param, :format => 'json'}
      assert_response :success
      get :show, {:id => host.to_param}
      assert_response :success
    end
  end
end
