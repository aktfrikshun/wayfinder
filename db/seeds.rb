parent = Parent.find_or_create_by!(email: "allen@example.com") do |p|
  p.name = "Allen"
end

Child.find_or_create_by!(inbound_alias: "zammy") do |child|
  child.parent = parent
  child.name = "Zammy"
  child.grade = "5"
end
