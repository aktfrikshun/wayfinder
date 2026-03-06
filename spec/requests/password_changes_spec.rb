require "rails_helper"

RSpec.describe "Password changes", type: :request do
  it "forces password update before accessing dashboard" do
    user = create(
      :user,
      email: "temp-pass@example.com",
      role: :parent,
      password: "TempPass123!",
      password_confirmation: "TempPass123!",
      must_change_password: true
    )

    sign_in(user)

    get parent_root_path
    expect(response).to redirect_to(edit_password_change_path)

    patch password_change_path, params: {
      user: {
        password: "NewPass456!",
        password_confirmation: "NewPass456!"
      }
    }

    expect(response).to redirect_to(parent_root_path)
    expect(user.reload.must_change_password).to be(false)
  end
end
