class JobInvocationChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'job_invocation_channel'
  end

  def unsubscribed
  end
end
