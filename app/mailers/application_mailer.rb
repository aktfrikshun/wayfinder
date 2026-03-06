class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "wayfinder@frikshun.com")
  layout "mailer"
end
