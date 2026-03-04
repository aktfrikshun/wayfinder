# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Test", "bundle exec rspec"
end
