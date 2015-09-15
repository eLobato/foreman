class HostConfigGroup < ActiveRecord::Base
  include Authorizable

  audited :associated_with => :host, :allow_mass_assignment => true
  audited :associated_with => :hostgroup, :allow_mass_assignment => true
  belongs_to :host, :polymorphic => true
  belongs_to :config_group

  attr_accessible :host_id, :config_group_id

  validates :host_id, :uniqueness => { :scope => [:config_group_id, :host_type] }
end
