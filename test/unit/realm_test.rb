require 'test_helper'

class RealmTest < ActiveSupport::TestCase
  def setup
    User.current = users(:admin)
    @new_realm = Realm.new
    @realm = realms(:myrealm)
  end

  should validate_presence_of(:name)
  should validate_uniqueness_of(:name)
  should have_many(:locations).
    source(:taxonomy).
    conditions("taxonomies.type=Location").
    through('taxable_taxonomies')

  test "when cast to string should return the name" do
    assert_equal @realm.name, @realm.to_s
  end

  test "should not destroy if it contains hosts" do
    disable_orchestration
    host = FactoryGirl.create(:host, :realm => @realm)
    assert host.save
    realm = host.realm
    assert !realm.destroy
    assert_match /is used by/, realm.errors.full_messages.join("\n")
  end

  # test taxonomix methods
  test "should get used location ids for host" do
    FactoryGirl.create(:host, :realm => @realm,
                       :location => taxonomies(:location1))
    assert_equal [taxonomies(:location1).id], realms(:myrealm).used_location_ids
  end

  test "should get used and selected location ids for host" do
    assert_equal [taxonomies(:location1).id], realms(:myrealm).used_or_selected_location_ids
  end
end

