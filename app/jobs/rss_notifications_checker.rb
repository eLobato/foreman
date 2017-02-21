require 'rss'
require 'date'

class RssNotificationsChecker < ApplicationJob
  queue_as :notifications
  attr_reader :url

  after_perform do |job|
    logger.info(_("Finished creating notifications for RSS feed: #{job.url}"))
    self.class.set(:wait => 12.hours).perform_later
  end

  def perform(options = {})
    @url = options[:url] || 'https://theforeman.org/feed.xml'.freeze
    @group = options[:group] || _('Community')
    @latest_posts = options[:latest_posts] || 3
    @expiration_date = options[:expiration_date] || 1.week
    @force_repost = options[:force_repost] || false
    @audience = options[:audience] || Notification::AUDIENCE_GLOBAL
    create_notifications
  end

  private

  def find_or_create_blueprint(item)
    name = item.title.content
    blueprint = NotificationBlueprint.find_by_name(name)
    # Return any previous notification blueprint with this name
    return blueprint if blueprint.present?
    summary = item.summary.content # display summary if available
    link = item.link.href # link href is indispensable
    NotificationBlueprint.new(
      :group => @group,
      :message => "#{summary} - #{link}",
      :level => 'info',
      :expires_in => @expiration_date,
      :name => name)
  end

  def create_notifications
    feed = RSS::Parser.parse(@url, false)
    feed.items[0, @latest_posts].each do |item|
      blueprint = find_or_create_blueprint(item)
      if blueprint.persisted?
        # If some blueprint exists use it already if force_repost is set
        # Otherwise do not use it, as it would create duplicate notifications
        next unless @force_repost
      end
      initiator = User.anonymous_admin
      notification = Notification.new(
        :initiator => initiator,
        :audience => @audience,
        :notification_blueprint => blueprint
      )
      blueprint.save
      notification.save
    end
  end
end
