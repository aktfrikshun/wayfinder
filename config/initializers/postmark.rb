if ENV["POSTMARK_API_TOKEN"].present? && !Rails.env.test?
  ActionMailer::Base.delivery_method = :postmark
  ActionMailer::Base.postmark_settings = {
    api_token: ENV.fetch("POSTMARK_API_TOKEN"),
    message_stream: ENV.fetch("POSTMARK_MESSAGE_STREAM", "outbound")
  }
end
