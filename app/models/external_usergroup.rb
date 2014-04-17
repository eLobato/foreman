class ExternalUsergroup < ActiveRecord::Base
  belongs_to :usergroup
  belongs_to :auth_source

  validates_uniqueness_of :name, :scope => :auth_source_id
  validates_presence_of   :name, :auth_source_id, :usergroup_id
end
