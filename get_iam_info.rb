#!/usr/bin/env ruby
#
# This script gets some IAM information.
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
end.parse!

puts "Using #{options[:aws_config_file]}."
aws_config_file = options[:aws_config_file]
unless File.exist?(aws_config_file)
  puts "#{aws_config_file} does not exist!"
  exit 1
end
aws_config = YAML.load(File.read(aws_config_file))
AWS.config(aws_config)

iam = AWS::IAM.new

summary = iam.account_summary
puts "Number of IAM users: #{summary[:users]}"
iam.users.each do |user|
  puts "#{user.name} (ARN: #{user.arn} - created at #{user.create_date})"
end
puts "Number of IAM groups: #{summary[:groups]}"
iam.groups.each do |group|
  puts "#{group.name} (ARN: #{group.arn} - created at #{group.create_date})"
end
iam_client = AWS::IAM::Client.new
role_list = iam_client.list_roles()[:roles]
puts "Number of IAM roles: #{role_list.count}"
role_list.each do |role|
  puts "#{role[:role_name]} (ARN: #{role[:arn]} - created at #{role[:create_date]})"
end
