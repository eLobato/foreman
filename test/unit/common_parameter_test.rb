require 'test_helper'

class CommonParameterTest < ActiveSupport::TestCase
  should validate_presence_of(:name)
  should_not validate_presence_of(:value)
  should validate_uniqueness_of(:name)
  should_not allow_value('   a new param').for(:name)
  should allow_value('   ').for(:value)
  should allow_value('   some crazy \"\'&<*%# value').for(:value)
end
