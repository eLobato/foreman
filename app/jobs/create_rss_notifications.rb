class CreateRssNotifications < ApplicationJob
  after_perform do |job|
    self.class.set(:wait => 12.hours).perform_later(job.arguments.first)
  end

  def perform(options = {})
    # Defaults to theforeman.org blog RSS
    UINotifications::RssNotificationsChecker.new(options).deliver!
  end

  rescue_from(StandardError) do |exception|
    Foreman::Logging.logger('background').error(
      'RSS notification checker: '\
      "Error while creating notifications #{exception}")
  end
end
