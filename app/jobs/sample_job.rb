class SampleJob < ApplicationJob
  def perform(msg)
    logger.info("#{msg}")
    logger.info("#{msg}")
    logger.info("#{msg}")
    logger.info("#{msg}")
    logger.info("#{msg}")
  end
end
