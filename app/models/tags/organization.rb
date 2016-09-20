module Tags
  class Organization < ActiveRecord::Base
    self.table_name = 'tags'

    validates_lengths_from_database
    validates :name, :presence => true

    after_save :create_default_tagging

    # Save creates a Tag, but in order for that Tag to be 'selectable'
    # we need to create a Tagging with the tag context, but no associations.
    def create_default_tagging
      tagging = ActsAsTaggableOn::Tagging.new(
        :tag_id => id,
        :context => context)
      tagging.save
    end

    def context
      self.class.name.demodulize.pluralize.downcase
    end

    def to_s
      name
    end
  end
end
