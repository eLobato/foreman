class CachedUsergroupMember < ActiveRecord::Base
  belongs_to :user
  belongs_to :usergroup
  include AccessibleAttributes
end
