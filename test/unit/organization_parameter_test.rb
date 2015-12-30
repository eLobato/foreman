require 'test_helper'

class OrganizationParameterTest < ActiveSupport::TestCase
  should validate_presence_of(:reference_id)
  should validate_presence_of(:name)
  should validate_uniqueness_of(:name).scope(:reference_id)
end
