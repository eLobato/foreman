class NotificationRecipient < ActiveRecord::Base
  belongs_to :notification
  belongs_to :user
  has_one :notification_blueprint, :through => :notification

  validates :notification, :presence => true
  validates :user, :presence => true

  scope :unseen, -> { where(:seen => false) }

  def payload
    {
      :id         => id,
      :seen       => seen,
      :level      => notification_blueprint.level,
      :text       => notification_blueprint.message,
      :subject    => notification_blueprint.subject,
      :created_at => notification.created_at,
    }
  end
end
