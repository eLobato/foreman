require 'rss'
require 'date'

module UINotifications
  class RssNotificationsChecker
    def initialize(options = [])
      @url = options[:url] || Setting[:rss_url]
      @latest_posts = options[:latest_posts] || 3
      @force_repost = options[:force_repost] || false
      @audience = options[:audience] || Notification::AUDIENCE_GLOBAL
    end

    def deliver!
      # This is a noop every time rss_enable=false, the moment it
      # gets enabled, notifications for RSS feeds are created again
      return true unless Setting[:rss_enable]
      feed = RSS::Parser.parse(@url, false)
      feed.items[0, @latest_posts].each do |item|
        blueprint = rss_notification_blueprint
        if notification_already_exists?(item)
          next unless @force_repost
        end
        Notification.create(
          :initiator => User.anonymous_admin,
          :audience => @audience,
          :message => item.title.content,
          :notification_blueprint => blueprint,
          :actions => {
            :links => [
              {
                :href => item.link.href,
                :title => _('Open'),
                :external => true
              }
            ]
          }
        )
      end
    end

    private

    def rss_notification_blueprint
      NotificationBlueprint.unscoped.find_by_name('rss_post')
    end

    def notification_already_exists?(item)
      !!Notification.unscoped.find_by_message(item.summary.content)
    end
  end
end
