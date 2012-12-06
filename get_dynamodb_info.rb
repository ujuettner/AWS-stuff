#!/usr/bin/env ruby
#
# This script gets some DynamoDB info.
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
option_parser.parse!

exit 1 unless aws_config(options[:aws_config_file])

db = AWS::DynamoDB.new

db.tables.each do |table|
  puts "Table: #{table.name}"
  puts "\tread capacity: #{table.read_capacity_units}"
  puts "\twrite capacity: #{table.write_capacity_units}"
  puts "\t\tlast decreased at: #{table.throughput_last_decreased_at || 'never'}"
  puts "\t\tlast increased at: #{table.throughput_last_increased_at || 'never'}"
end
