module Tags
  class Organization
    include ActiveModel::Model

    attr_accessor :name

    # Save represents creating a Tag, and a Tagging with the tag context,
    # but no associations.
    # This allows the Tag to be 'taggable' on the views. Otherwise you
    # would have to create the tag at the same time it's assigned, via
    # a text field.
    def save
      return false unless valid?
      tag = ActsAsTaggableOn::Tag.new(:name => name)
      return false unless tag.save
      tagging = ActsAsTaggableOn::Tagging.new(
        :tag_id => tag.id,
        :context => context)
      tagging.save
    end

    def all
      ActsAsTaggableOn::Tagging.where(
        :context => context,
        :taggable_id => nil)
    end

    def context
      self.class.name.demodulize.pluralize.downcase
    end

    def to_s
      name
    end
  end
end
