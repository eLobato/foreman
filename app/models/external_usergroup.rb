class ExternalUsergroup < ActiveRecord::Base
  belongs_to :usergroup
  belongs_to :auth_source

  validates_uniqueness_of :name, :scope => :auth_source_id
  validates_presence_of   :name, :auth_source_id, :usergroup_id
  validate :in_auth_source?

  private
  def in_auth_source?(source = auth_source)
    errors.add :name, _("is not an LDAP user group") unless source.includes_cn?(name)
  end
end
