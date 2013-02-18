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
  print "Table: #{table.name} "
  # takes a rather long time to return:
  #print "items: #{table.items.count} "
  print "read_capacity: #{table.read_capacity_units} "
  print "write_capacity: #{table.write_capacity_units} "
  print "last_decreased_at: #{table.throughput_last_decreased_at || 'never'} "
  puts "last_increased_at: #{table.throughput_last_increased_at || 'never'}"
end
