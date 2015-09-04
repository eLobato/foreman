module ConfigTemplatesControllerTest
  extend ActiveSupport::Concern
  included do
    test "should get index" do
      get :index
      templates = ActiveSupport::JSON.decode(@response.body)
      assert !templates.empty?, "Should response with template"
      assert_response :success
    end

    test "should not create invalid" do
      post :create
      assert_response 422
    end

    test "should update valid" do
      ProvisioningTemplate.any_instance.stubs(:valid?).returns(true)
      put :update, { :id              => templates(:pxekickstart).to_param,
                     :config_template => { :template => "blah" } }
      assert_response :ok
    end

    test "should not update invalid" do
      put :update, { :id              => templates(:pxekickstart).to_param,
                     :config_template => { :name => "" } }
      assert_response 422
    end

    test "should not destroy template with associated hosts" do
      config_template = templates(:pxekickstart)
      delete :destroy, { :id => config_template.to_param }
      assert_response 422
      assert ProvisioningTemplate.exists?(config_template.id)
    end

    test "should destroy" do
      config_template = templates(:pxekickstart)
      config_template.os_default_templates.clear
      delete :destroy, { :id => config_template.to_param }
      assert_response :ok
      refute ProvisioningTemplate.exists?(config_template.id)
    end

    test "should add audit comment" do
      ProvisioningTemplate.auditing_enabled = true
      ProvisioningTemplate.any_instance.stubs(:valid?).returns(true)
      put :update, { :id              => templates(:pxekickstart).to_param,
                     :config_template => { :audit_comment => "aha", :template => "tmp" } }
      assert_response :success
      assert_equal "aha", templates(:pxekickstart).audits.last.comment
    end
  end
end
