#!/usr/bin/env ruby
#
# This script changes the r/w capacity units of matching DynamoDB tables.
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
options[:table_name_expr] = 'my_table'
option_parser.on('-t', '--table-name-expr EXPR',
  "table name expression (default: #{options[:table_name_expr]})") do |t|
  options[:table_name_expr] = t
end
options[:read_capacity_units] = 0
option_parser.on('-r', '--read-capacity-units CAPACITY_UNITS', OptionParser::DecimalInteger,
  "read capacity units (default: #{options[:read_capacity_units]})") do |r|
  options[:read_capacity_units] = r
end
options[:write_capacity_units] = 0
option_parser.on('-w', '--write-capacity-units CAPACITY_UNITS', OptionParser::DecimalInteger,
  "write capacity units (default: #{options[:write_capacity_units]})") do |w|
  options[:write_capacity_units] = w
end
option_parser.parse!

exit 1 unless aws_config(options[:aws_config_file])

read_capacity_units = options[:read_capacity_units]
write_capacity_units = options[:write_capacity_units]
if read_capacity_units < 1 || write_capacity_units < 1
  puts 'Please set each capacity units to at least 1.'
  exit 1
end

db = AWS::DynamoDB.new

db.tables.each do |table|
  if table.name =~ /#{options[:table_name_expr]}/
    puts "Table: #{table.name} - read capacity units: #{table.read_capacity_units} - write capacity units: #{table.write_capacity_units} - status: #{table.status}"
    print "\tSetting r/w capacity units to #{read_capacity_units}/#{write_capacity_units}..."
    table.provision_throughput(:read_capacity_units => read_capacity_units, :write_capacity_units => write_capacity_units)
    sleep 1 while table.status == :updating
    puts 'done.'
    puts "Table: #{table.name} - read capacity units: #{table.read_capacity_units} - write capacity units: #{table.write_capacity_units} - status: #{table.status}"
  end
end

