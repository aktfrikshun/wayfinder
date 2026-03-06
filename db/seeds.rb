allen_family = Family.find_or_create_by!(name: "Allen Family")

parent = Parent.find_or_create_by!(email: "allen@example.com") do |p|
  p.family = allen_family
  p.name = "Allen"
end

parent_user_family = Family.find_or_create_by!(name: "Wayfinder Parent Family")
Parent.find_or_create_by!(email: "parent@wayfinder.local") do |p|
  p.family = parent_user_family
  p.name = "Parent User"
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
  { email: "teacher@wayfinder.local", role: :teacher },
  { email: "relative@wayfinder.local", role: :relative }
].each do |user_data|
  user = User.find_or_initialize_by(email: user_data[:email])
  user.role = user_data[:role]
  user.password = "Password123!"
  user.password_confirmation = "Password123!"
  user.save!
end
