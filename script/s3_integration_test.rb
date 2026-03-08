#!/usr/bin/env ruby
require "aws-sdk-s3"
require "optparse"

options = {
  family: nil,
  communication: nil,
  key: "test.txt",
  content: "hello from s3_integration_test"
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby script/s3_integration_test.rb [options]"

  opts.on("-fVALUE", "--family=VALUE", "Family id (required)") { |v| options[:family] = v }
  opts.on("-cVALUE", "--communication=VALUE", "Communication id (required)") { |v| options[:communication] = v }
  opts.on("-kVALUE", "--key=VALUE", "Object key name (default: test.txt)") { |v| options[:key] = v }
  opts.on("-mVALUE", "--message=VALUE", "Content to upload (default sample)") { |v| options[:content] = v }
  opts.on("-h", "--help", "Show this help") { puts opts; exit }
end.parse!

missing = []
%w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION AWS_BUCKET].each do |v|
  missing << v unless ENV[v] && !ENV[v].empty?
end
if missing.any?
  warn "Missing required env vars: #{missing.join(', ')}"
  warn "Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, AWS_BUCKET"
  exit 1
end

if options[:family].nil? || options[:communication].nil?
  warn "--family and --communication are required"
  exit 1
end

bucket = ENV.fetch("AWS_BUCKET")
region = ENV.fetch("AWS_REGION")
endpoint = ENV["AWS_ENDPOINT"]
force_path_style = ENV["AWS_FORCE_PATH_STYLE"] == 'true'

client_args = { region: region }
client_args[:access_key_id] = ENV["AWS_ACCESS_KEY_ID"]
client_args[:secret_access_key] = ENV["AWS_SECRET_ACCESS_KEY"]
client_args[:session_token] = ENV["AWS_SESSION_TOKEN"] if ENV["AWS_SESSION_TOKEN"]
client_args[:endpoint] = endpoint if endpoint && !endpoint.empty?
client_args[:force_path_style] = true if force_path_style

client = Aws::S3::Client.new(client_args)

begin
  client.head_bucket(bucket: bucket)
  puts "Bucket '#{bucket}' exists and is accessible."
rescue Aws::S3::Errors::NotFound
  warn "Bucket '#{bucket}' does not exist."
  exit 1
rescue Aws::S3::Errors::Forbidden, Aws::S3::Errors::AccessDenied => e
  warn "Access denied to bucket '#{bucket}': #{e.message}"
  exit 1
end

prefix_family = "#{options[:family]}/"
prefix_comm = "#{options[:family]}/#{options[:communication]}/"
object_key = "#{prefix_comm}#{options[:key]}"

puts "\nListing objects at family prefix: #{prefix_family}"
resp = client.list_objects_v2(bucket: bucket, prefix: prefix_family, max_keys: 50)
if resp.contents.nil? || resp.contents.empty?
  puts "(none)"
else
  resp.contents.each { |o| puts " - #{o.key} (#{o.size} bytes)" }
end

puts "\nUploading sample object to: #{object_key}"
client.put_object(bucket: bucket, key: object_key, body: options[:content])
puts "Uploaded."

puts "\nListing objects at communication prefix: #{prefix_comm}"
resp2 = client.list_objects_v2(bucket: bucket, prefix: prefix_comm, max_keys: 50)
if resp2.contents.nil? || resp2.contents.empty?
  puts "(none)"
else
  resp2.contents.each { |o| puts " - #{o.key} (#{o.size} bytes)" }
end

puts "\nRetrieving object: #{object_key}"
got = client.get_object(bucket: bucket, key: object_key)
body = got.body.read
puts "Content (first 1KB):\n#{body[0..1024]}"

puts "\nDeleting object: #{object_key}"
client.delete_object(bucket: bucket, key: object_key)
puts "Deleted."

puts "\nFinal list at communication prefix: #{prefix_comm}"
resp3 = client.list_objects_v2(bucket: bucket, prefix: prefix_comm, max_keys: 50)
if resp3.contents.nil? || resp3.contents.empty?
  puts "(none)"
else
  resp3.contents.each { |o| puts " - #{o.key} (#{o.size} bytes)" }
end

puts "\nS3 integration test complete."
