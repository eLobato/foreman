require 'yaml'

job_already_exists = false

Delayed::Job.where(:queue => 'notifications').each do |notification_job|
  if 'RssNotificationsChecker' == YAML.load(notification_job.handler).job_data["job_class"]
    job_already_exists = true
  end
end

options = {}
options[:url] = 'https://theforeman.org/feed.xml'.freeze
options[:group] = _('Community')
options[:latest_posts] = 3
options[:expiration_date] = 1.week
options[:force_repost] = false
options[:audience] = Notification::AUDIENCE_GLOBAL
RssNotificationsChecker.perform_now(options) unless job_already_exists || Rails.env.test?
