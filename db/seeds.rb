parent = Parent.find_or_create_by!(email: "allen@example.com") do |p|
  p.name = "Allen"
end

Child.find_or_create_by!(inbound_alias: "zammy") do |child|
  child.parent = parent
  child.name = "Zammy"
  child.grade = "5"
end

[
  { email: "admin@wayfinder.local", role: :admin },
  { email: "parent@wayfinder.local", role: :parent },
  { email: "child@wayfinder.local", role: :child },
  { email: "teacher@wayfinder.local", role: :teacher }
].each do |user_data|
  user = User.find_or_initialize_by(email: user_data[:email])
  user.role = user_data[:role]
  user.password = "Password123!"
  user.password_confirmation = "Password123!"
  user.save!
end
