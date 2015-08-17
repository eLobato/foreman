require 'test_helper'

class DomainParameterTest < ActiveSupport::TestCase
  should validate_presence_of(:name)
  should validate_uniqueness_of(:name).scoped_to(:reference_id)
  should belong_to(:domain).with_foreign_key(:reference_id)
end

