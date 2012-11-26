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

require 'optparse'
require 'yaml'
require 'aws-sdk'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options]"

  options[:aws_config_file] = './aws_config.yml'
  opts.on('-c', '--aws-config FILENAME',
    "AWS config file (default: #{options[:aws_config_file]})") do |c|
    options[:aws_config_file] = c
  end

  options[:regex_for_name] = '\Atest-tmp-.*\Z'
  opts.on('-r', '--regex-for-name REGEX',
    "regular expression the user name must match (default: #{options[:regex_for_name]})") do |r|
    options[:regex_for_name] = r
  end
end.parse!

puts "Using #{options[:aws_config_file]}."
aws_config_file = options[:aws_config_file]
unless File.exist?(aws_config_file)
  puts "#{aws_config_file} does not exist!"
  exit 1
end
aws_config = YAML.load(File.read(aws_config_file))
AWS.config(aws_config)

puts "Regular expression for user name: #{options[:regex_for_name]}"

iam = AWS::IAM.new

summary = iam.account_summary
puts "Current number of IAM users: #{summary[:users]}"
iam.users.each do |user|
  if user.name =~ /#{options[:regex_for_name]}/
    print "Deleting user #{user.name} (ARN: #{user.arn}) incl. its profiles, mfa devices, keys and certs and removing it from all groups..."
    user.delete!
    puts 'done.'
  end
end
puts "Current number of IAM users: #{summary[:users]}"
