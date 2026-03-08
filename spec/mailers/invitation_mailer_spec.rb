require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe "#family_invite" do
    let(:base_params) do
      {
        email: "invitee@example.com",
        inviter_name: "Inviter",
        role_label: "Parent",
        temporary_password: "TempPassword1!"
      }
    end

    it "renders successfully when login_url is not provided" do
      mail = described_class.with(base_params).family_invite

      expect(mail.subject).to eq("You're invited to Wayfinder")
      expect(mail.to).to eq([ "invitee@example.com" ])
      expect(mail.from).to eq([ ENV.fetch("MAIL_FROM", "wayfinder@frikshun.com") ])
      expect(mail.body.encoded).to include("Sign in to Wayfinder")
      expect(mail.body.encoded).to include("/users/sign_in")
    end

    it "uses provided login_url when present" do
      login_url = "https://wayfinder.frikshun.com/users/sign_in"
      mail = described_class.with(base_params.merge(login_url: login_url)).family_invite

      expect(mail.body.encoded).to include(login_url)
    end
  end
end
