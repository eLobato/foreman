module UsergroupMemberTaxonomiesUpdater
  extend ActiveSupport::Concern

  included do
    after_save :add_usergroup_taxonomies!
    after_destroy :remove_usergroup_taxonomies!
  end

  def add_usergroup_taxonomies!
    member.taxonomies = (member_taxonomies +
                         member.usergroups.map(&:all_taxonomies)).flatten.uniq
  end

  def remove_usergroup_taxonomies!
    member.taxonomies = member.taxonomies - usergroup.all_taxonomies
  end

  def member_taxonomies
    original_taxonomies = member.all_taxonomies
    if changes.present? && changes['usergroup_id'].first.present?
      old_taxonomies = member.usergroups_was.map(&:all_taxonomies)
    else
      old_taxonomies = []
    end
    new_taxonomies = member.usergroups.map(&:all_taxonomies)

    (original_taxonomies - old_taxonomies + new_taxonomies).flatten.uniq
  end
end
