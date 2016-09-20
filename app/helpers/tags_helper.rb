module TagsHelper
  def tags_context(context)
    ActsAsTaggableOn::Tag.includes(:taggings).
      where(taggings: { context: context }).
      uniq(:name).order(:name)
  end

  def new_tag_string
    _("New #{controller_name.humanize.singularize}")
  end

  def delete_button(tag)
    binding.pry
    display_delete_if_authorized(
      organization_path(tag),
      :data => {
        :confirm => tag.smart_proxies.count.zero? ? _("Delete %s?") % tag.name :
        n_("%{tag_type} %{tag_name} has %{count} smart proxy that will need to \
          be reassociated after deletion. Delete %{tag_name2}?",
          "%{tag_type} %{tag_name} has %{count} smart proxies that will need to be \
          reassociated after deletion. Delete %{tag_name2}?",
          tag.smart_proxies.count) % {
            :tag_type => tag_title,
            :tag_name => tag.name,
            :count => tag.smart_proxies.count,
            :tag_name2 => tag.name }
      },
      :action => :destroy)
  end
end
