module TagsHelper
  def tags_context(context)
    ActsAsTaggableOn::Tag.includes(:taggings).
      where(taggings: { context: context }).
      uniq(:name).order(:name)
  end

  def new_tag_string
    _("New #{controller_name.humanize.singularize}")
  end
end
