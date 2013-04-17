class ExternalUsergroup < ActiveRecord::Base
  belongs_to :usergroup, :inverse_of => :external_usergroups
  belongs_to :auth_source

  validates_uniqueness_of :name, :scope => :auth_source_id
  validates_presence_of   :name, :auth_source, :usergroup
  validate :in_auth_source?, :if => Proc.new { |eu| eu.auth_source.type == 'AuthSourceLdap' }

  def refresh
    if auth_source.class == AuthSourceLdap
      current_users  = usergroup.users.map(&:login)
      all_ldap_users = usergroup.external_usergroups.map(&:ldap_users).flatten.uniq

      # We need to make sure when we refresh a external_usergroup
      # other external_usergroup LDAP users remain in. Otherwise refreshing
      # a external user group with no users in LDAP will empty the user group.
      old_ldap_users = current_users  - all_ldap_users
      new_ldap_users = ldap_users - current_users

      usergroup.remove_users(old_ldap_users)
      usergroup.add_users(new_ldap_users)
      true
    else
      false
    end
  end

  def ldap_users
    auth_source.ldap_con.user_list(name)
  end

  private

  def in_auth_source?(source = auth_source)
    begin
      ldap_con = source.ldap_con
      ldap_con.authenticate?(source.account, source.account_password)
      errors.add :name, _("is not an LDAP user group") unless ldap_con.ldap.includes_cn?(name)
    rescue Net::LDAP::LdapError => e
      errors.add :auth_source_id, _("LDAP error - %{message}") % { :message => e.message }
    end
  end
end
