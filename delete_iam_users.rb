#!/usr/bin/env ruby
#
# This script deletes IAM users, whose name matches a given regular expression,
# incl. its profiles, mfa devices, keys and certs and removing it from all
# groups.
#
# The AWS SDK for Ruby is required. See https://aws.amazon.com/sdkforruby/ for
# installation instructions.
#
# AWS account keys are loaded from a YAML file which has the following format:
# access_key_id: <your access key id>
# secret_access_key: <your secret access key>
#

require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'aws_config'))

options = {}
option_parser = add_default_options(options)
options[:regex_for_name] = '\Atest-tmp-.*\Z'
option_parser.on('-r', '--regex-for-name REGEX',
  "regular expression the user name must match (default: #{options[:regex_for_name]})") do |r|
  options[:regex_for_name] = r
end
option_parser.parse!

exit 1 unless aws_config(options[:aws_config_file])

iam = AWS::IAM.new

puts "Regular expression for user name: #{options[:regex_for_name]}"

summary = iam.account_summary
puts "Current number of IAM users: #{summary[:users]}"
iam.users.each do |user|
  if user.name =~ /#{options[:regex_for_name]}/
    print "Deleting user #{user.name} (ARN: #{user.arn}) incl. its profiles, mfa devices, keys and certs and removing it from all groups..."
    user.delete!
    puts 'done.'
  end
end
