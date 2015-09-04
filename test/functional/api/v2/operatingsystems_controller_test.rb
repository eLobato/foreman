require 'test_helper'
require_relative '../shared/operatingsystems_controller_test'

class Api::V2::OperatingsystemsControllerTest < ActionController::TestCase
  include ::OperatingsystemsControllerTest

  test "should update associated architectures by ids with UNWRAPPED node" do
    os = operatingsystems(:redhat)
    assert_difference('os.architectures.count') do
      put :update, { :id => operatingsystems(:redhat).to_param, :operatingsystem => { },
                     :architectures => [{ :id => architectures(:x86_64).id }, { :id => architectures(:sparc).id } ] }
    end
    assert_response :success
  end

  test "should update associated architectures by name with UNWRAPPED node" do
    os = operatingsystems(:redhat)
    assert_difference('os.architectures.count') do
      put :update, { :id => operatingsystems(:redhat).to_param,  :operatingsystem => { },
                     :architectures => [{ :name => architectures(:x86_64).name }, { :name => architectures(:sparc).name } ] }
    end
    assert_response :success
  end

  test "should add association of architectures by ids with WRAPPED node" do
    os = operatingsystems(:redhat)
    assert_difference('os.architectures.count') do
      put :update, { :id => operatingsystems(:redhat).to_param, :operatingsystem => { :architectures => [{ :id => architectures(:x86_64).id }, { :id => architectures(:sparc).id }] } }
    end
    assert_response :success
  end

  test "should add association of architectures by name with WRAPPED node" do
    os = operatingsystems(:redhat)
    assert_difference('os.architectures.count') do
      put :update, { :id => operatingsystems(:redhat).to_param,  :operatingsystem => { :architectures => [{ :name => architectures(:x86_64).name }, { :name => architectures(:sparc).name }] } }
    end
    assert_response :success
  end

  test "should remove association of architectures with WRAPPED node" do
    os = operatingsystems(:redhat)
    assert_difference('os.architectures.count', -1) do
      put :update, { :id => operatingsystems(:redhat).to_param, :operatingsystem => {:architectures => [] } }
    end
    assert_response :success
  end
end
