require 'test_helper'

class AtomicTest < ActiveSupport::TestCase
  test 'returns initrd under isolinux' do
    fedora_atomic = FactoryGirl.create(:operatingsystem, :name => 'Fedora-Atomic', :type => 'Redhat')
    # We need to find the OS to make load the class Redhat, fedora_atomic is simply Operatingsystem at this point
    assert_equal 'isolinux/initrd.img', Operatingsystem.find(fedora_atomic.id).initrd(fedora_atomic.architectures.first)
  end
end
