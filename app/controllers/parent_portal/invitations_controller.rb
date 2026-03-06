module ParentPortal
  class InvitationsController < BaseController
    def index
      @family_users = User.joins(contact: :family)
        .where(contacts: { family_id: @parent.family_id })
        .order(:email)
        .distinct
    end

    def new
      @invite = invite_defaults
    end

    def create
      @invite = invite_defaults.merge(invite_params.to_h.symbolize_keys)
      email = @invite[:email].to_s.downcase.strip
      role = @invite[:role].to_s

      if email.blank?
        flash.now[:alert] = "Email is required."
        return render :new, status: :unprocessable_entity
      end

      if User.exists?(email: email)
        flash.now[:alert] = "A user with that email already exists."
        return render :new, status: :unprocessable_entity
      end

      temporary_password = generate_temporary_password

      ActiveRecord::Base.transaction do
        user = User.create!(
          email: email,
          role: role,
          password: temporary_password,
          password_confirmation: temporary_password,
          must_change_password: true,
          temporary_password_sent_at: Time.current,
          invited_by: current_user
        )

        contact = user.correspondent || user.build_correspondent
        contact.family = @parent.family
        contact.name = @invite[:name].presence || email
        contact.email = email
        contact.save!

        if user.parent_role?
          parent_profile = Parent.find_or_initialize_by(email: email)
          parent_profile.family = @parent.family
          parent_profile.name = contact.name
          parent_profile.save!
        end

        InvitationMailer.with(
          email: email,
          inviter_name: current_user.correspondent&.display_name || current_user.email,
          role_label: user.role_label,
          temporary_password: temporary_password,
          login_url: new_user_session_url
        ).family_invite.deliver_later
      end

      redirect_to parent_invitations_path, notice: "Invitation sent to #{email}."
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end

    private

    def invite_defaults
      {
        name: "",
        email: "",
        role: "relative"
      }
    end

    def invite_params
      params.require(:invite).permit(:name, :email, :role)
    end

    def generate_temporary_password
      loop do
        candidate = "#{SecureRandom.base58(18)}aA1!"
        return candidate if candidate.match?(/[a-z]/) && candidate.match?(/[A-Z]/) && candidate.match?(/\d/) && candidate.match?(/[^A-Za-z0-9]/)
      end
    end
  end
end
