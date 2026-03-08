class InvitationMailer < ApplicationMailer
  def family_invite
    @inviter_name = params[:inviter_name]
    @role_label = params[:role_label]
    @temporary_password = params[:temporary_password]
    @login_url = params[:login_url].presence || fallback_login_url

    mail(to: params[:email], subject: "You're invited to Wayfinder")
  end

  private

  def fallback_login_url
    new_user_session_url
  rescue StandardError
    nil
  end
end
