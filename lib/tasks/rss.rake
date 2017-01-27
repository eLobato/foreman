require 'rss'

namespace :rss do
  desc <<-END_DESC
Create notifications from an RSS feed.

By default, the last 3 posts from the feed are sent to a global audience,
and expire in one week since the announcement. Previous posts in the feed will not
create a new notification unless "FOREMAN_RSS_FORCE_REPOST" is set to true.

It accepts the following environment variables:
 - FOREMAN_RSS_URL
   + An RSS URL and finds the latest posts, by default 'https://theforeman.org/feed.xml'
 - FOREMAN_RSS_LATEST_POSTS
   + The number of latest posts to retrieve, by default '3'
 - FOREMAN_RSS_NOTIFICATION_GROUP
   + The notification group the messages will show up under. By default, 'Foreman Community'
 - FOREMAN_RSS_FORCE_REPOST
   + If 'true', the task will send notifications again for posts in the RSS feed that already created
     notifications.
   + For example, on the first run of this task, it creates notifications for the latest 3 posts,
     "Newsletter December", "Newsletter November", "Newsletter October". If you run it again without
     FOREMAN_RSS_FORCE_REPOST, no new notifications will be created for these three posts. If you do,
     the task will create notifications once again for "Newsletter December", November and October.
 - FOREMAN_RSS_EXPIRATION_DATETIME
   + The date and time when the notification should expire, by default in one week from now (UTC).
     It can take any time that is able to parse, e.g: 2017-01-27 15:59:37 UTC
 - FOREMAN_RSS_AUDIENCE
   + The audience that will recieve the notification. By default, 'global'
   + Possible values:
     - 'global' - All users will receive the notification
     - 'admin' - Only administrator users will receive the notification

Examples:
  # foreman-rake rss:create_notifications FOREMAN_RSS_AUDIENCE='admin'
END_DESC

  task :create_notifications => :environment do
    url = ENV['FOREMAN_RSS_URL'] || 'https://theforeman.org/feed.xml'
    feed = RSS::Parser.parse(url, false)
    feed.items[0, ENV['FOREMAN_RSS_LATEST_POSTS'] || 3].each do |item|
      group = ENV['FOREMAN_RSS_NOTIFICATION_GROUP'] || 'Foreman Community'
      name = item.title.content
      summary = item.summary.content # display summary if available
      link = item.link.href # link href is indispensable
      expiration_date = 1.week

      # Find previous notification blueprints with this name.
      if (blueprint = NotificationBlueprint.find_by_name(name))
        # If some exist and FOREMAN_RSS_FORCE_REPOST, use them
        next unless ENV['FOREMAN_RSS_FORCE_REPOST'] == 'true'
      else
        # If none exist, create one.
        blueprint = NotificationBlueprint.new(
          :group => group,
          :message => "#{summary} - #{link}",
          :level => 'info',
          :expires_in => expiration_date,
          :name => name)
      end
      # Create a notification using the blueprint
      audience = ENV['FOREMAN_RSS_NOTIFICATION_GROUP'] || 'global'
      initiator = User.anonymous_admin
      notification = Notification.new(
        :initiator => initiator,
        :audience => audience,
        :notification_blueprint => blueprint
      )
      blueprint.save
      notification.save
    end
  end
end
