# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'net/ldap'

class AuthSourceLdap < AuthSource
  validates :host, :presence => true, :length => {:maximum => 60}, :allow_nil => true
  validates :attr_login, :attr_firstname, :attr_lastname, :attr_mail, :presence => true, :if => Proc.new { |auth| auth.onthefly_register? }
  validates :attr_login, :attr_firstname, :attr_lastname, :attr_mail, :length => {:maximum => 30}, :allow_nil => true
  validates :name, :account_password, :length => {:maximum => 60}, :allow_nil => true
  validates :account, :base_dn, :ldap_filter, :length => {:maximum => 255}, :allow_nil => true
  validates :port, :presence => true, :numericality => {:only_integer => true}
  validates :server_type, :presence => true
  validate :validate_ldap_filter, :unless => Proc.new { |auth| auth.ldap_filter.blank? }

  before_validation :strip_ldap_attributes
  after_initialize :set_defaults

  SERVER_TYPES = { :free_ipa => 'FreeIPA', :active_directory => 'ActiveDirectory',
                   :posix    => 'Posix'}

  # Loads the LDAP info for a user and authenticates the user with their password
  # Returns : Array of Strings.
  #           Either the users's DN or the user's full details OR nil
  def authenticate(login, password)
    return nil if login.blank? || password.blank?

    logger.debug "LDAP-Auth with User #{login}"

    entry = search_for_user_entry(login)
    attrs = attributes_values(entry)

    # not sure if there is a case were search result without a DN
    # but just to be on the safe side.
    if (dn=attrs.delete(:dn)).empty?
      logger.warn "no DN"
      return nil
    end

    logger.debug "DN found for #{login}: #{dn}"

    # finally, authenticate user
    ldap_con = initialize_ldap_con(dn, password)
    unless ldap_con.bind
      logger.warn "Result: #{ldap_con.get_operation_result.code}"
      logger.warn "Message: #{ldap_con.get_operation_result.message}"
      logger.warn "Failed to authenticate #{login}"
      return nil
    end

    update_usergroups(entry)

    attrs
  rescue Net::LDAP::LdapError => text
    raise "LdapError: %s" % text
  end

  def test_connection
    ldap_con = initialize_ldap_con(self.account, self.account_password)
    ldap_con.open { }
  rescue Net::LDAP::LdapError => text
    raise "LdapError: %s" % text
  end

  def auth_method_name
    "LDAP"
  end

  def includes_cn?(cn)
    filter     = Net::LDAP::Filter.eq("cn", cn)
    ldap_fluff = LdapFluff.new(self.to_config)
    ldap_con(ldap_fluff).search(:base => base_dn, :filter => filter).present?
  end

  def userlist(group)
    ldap_fluff = LdapFluff.new(self.to_config)
    return nil unless ldap_fluff.valid_group?(group)

    group_filter = ldap_fluff.ldap.member_service.group_filter(group)
    search       = ldap_con(ldap_fluff).search(:base => base_dn, :filter => group_filter).last
    return [] unless search.respond_to? :member

    members  = search.member
    get_logins(members)
  end

  def to_config
    { :host    => host,    :port => port, :encryption => (tls ? :start_tls : nil),
      :base_dn => base_dn, :group_base => groups_base,
      :server_type  => server_type.to_sym, :service_user => account,
      :service_pass => account_password,   :anon_queries => anon_queries }
  end

  private

  def strip_ldap_attributes
    [:attr_login, :attr_firstname, :attr_lastname, :attr_mail].each do |attr|
      write_attribute(attr, read_attribute(attr).strip) unless read_attribute(attr).nil?
    end
  end

  def initialize_ldap_con(ldap_user, ldap_password)
    options = { :host       => host,
                :port       => port,
                :encryption => (tls ? :simple_tls : nil)
    }
    options.merge!(:auth => { :method => :simple, :username => ldap_user, :password => ldap_password }) unless ldap_user.blank? && ldap_password.blank?
    Net::LDAP.new options
  end

  def ldap_con(ldap_fluff)
    ldap_fluff.ldap.ldap
  end

  def set_defaults
    self.port ||= 389
  end

  def required_ldap_attributes
    return {:dn => :dn} unless onthefly_register?
    { :firstname => attr_firstname,
      :lastname  => attr_lastname,
      :mail      => attr_mail,
      :dn        => :dn,
    }
  end

  def optional_ldap_attributes
    { :avatar => attr_photo }
  end

  def attributes_values entry
    Hash[required_ldap_attributes.merge(optional_ldap_attributes).map do |name, value|
      next if value.blank? || (entry[value].blank? && optional_ldap_attributes.keys.include?(name))
      if name.eql? :avatar
        [:avatar_hash, store_avatar(entry[value].first)]
      else
        value = entry[value].is_a?(Array) ? entry[value].first : entry[value]
        [name, value.to_s]
      end
    end]
  end

  def get_groups(grouplist)
    p = proc { |g| g.sub(/.*?cn=(.*?),.*/, '\1') }
    grouplist.collect(&p)
  end

  def get_logins(grouplist)
    p = proc { |g| g.sub(/.*?#{(attr_login || 'uid')}=(.*?),.*/, '\1') }
    grouplist.collect(&p)
  end

  def store_avatar avatar
    avatar_path = "#{Rails.public_path}/assets/avatars"
    avatar_hash = Digest::SHA1.hexdigest(avatar)
    avatar_file = "#{avatar_path}/#{avatar_hash}.jpg"
    unless FileTest.exist? avatar_file
      FileUtils.mkdir_p(avatar_path)
      File.open(avatar_file, 'w') { |f| f.write(avatar) }
    end
    avatar_hash
  end

  def validate_ldap_filter
    Net::LDAP::Filter.construct(ldap_filter)
  rescue Net::LDAP::LdapError => text
    errors.add(:ldap_filter, _("invalid LDAP filter syntax"))
  end

  def search_for_user_entry(login)
    ldap_fluff = LdapFluff.new(self.to_config)
    return nil unless ldap_fluff.valid_user?(login)

    if attr_login.blank?
      login_filter = ldap_fluff.ldap.member_service.name_filter(login)
    else
      login_filter = Net::LDAP::Filter.eq(attr_login, login)
    end

    object_filter = Net::LDAP::Filter.eq('objectClass', '*')
    object_filter = object_filter & Net::LDAP::Filter.construct(ldap_filter) unless ldap_filter.blank?

    entries = ldap_con(ldap_fluff).search(:base => base_dn, :filter => object_filter & login_filter)

    unless ldap_con(ldap_fluff).get_operation_result.code == 0
      logger.warn "Search Result: #{ldap_con(ldap_fluff).get_operation_result.code}"
      logger.warn "Search Message: #{ldap_con(ldap_fluff).get_operation_result.message}"
    end

    entries ? entries.last : nil
  end

  def update_usergroups(entry)
    if entry.respond_to? :memberof
      group_list = entry.memberof
    elsif entry.respond_to? :ismemberof
      group_list = entry.ismemberof
    else
      return
    end

    group_list.each do |name|
      begin
      Usergroup.find_by_name(name).refresh_ldap
      rescue
      end
    end
  end

end
