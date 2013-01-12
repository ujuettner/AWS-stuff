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
option_parser.on('-x', '--table-name-expr EXPR',
  "table name expression (default: #{options[:table_name_expr]})") do |x|
  options[:table_name_expr] = x
end
options[:read_capacity_units] = 0
option_parser.on('-r', '--read-capacity-units NUMBER', OptionParser::DecimalInteger,
  "read capacity units (default: #{options[:read_capacity_units]})") do |r|
  options[:read_capacity_units] = r
end
options[:write_capacity_units] = 0
option_parser.on('-w', '--write-capacity-units NUMBER', OptionParser::DecimalInteger,
  "write capacity units (default: #{options[:write_capacity_units]})") do |w|
  options[:write_capacity_units] = w
end
options[:num_threads] = 10
option_parser.on('-t', '--number-of-threads NUMBER', OptionParser::DecimalInteger,
  "number of threads, i.e. number tables per batch (default: #{options[:num_threads]})") do |t|
  options[:num_threads] = t
end
options[:wait_seconds] = 60.0
option_parser.on('-s', '--wait-seconds NUMBER', OptionParser::DecimalNumeric,
  "seconds to wait to pick the next batch of tables (default: #{options[:wait_seconds]})") do |s|
  options[:wait_seconds] = s
end
option_parser.parse!

exit 1 unless aws_config(options[:aws_config_file])

read_capacity_units = options[:read_capacity_units]
write_capacity_units = options[:write_capacity_units]
if read_capacity_units < 1 || write_capacity_units < 1
  puts 'Please set each capacity units to at least 1.'
  exit 1
end
if options[:num_threads] < 1
  puts 'Please set the number of threads to at least 1.'
  exit 1
end

db = AWS::DynamoDB.new

table_list = []
db.tables.each do |table|
  table_list << table if table.name =~ /#{options[:table_name_expr]}/
end
puts "Found #{table_list.length} matching tables."

thread_list = []
per_batch_counter = 0
table_list.each do |table|
  per_batch_counter += 1
  if per_batch_counter > options[:num_threads]
    thread_list.map(&:join)
    thread_list = []
    per_batch_counter = 1
    puts "Waiting #{options[:wait_seconds]} seconds ..."
    sleep options[:wait_seconds]
  end
  thread_list << Thread.new do
    old_read_capacity_units = table.read_capacity_units
    old_write_capacity_units = table.write_capacity_units
    begin
      puts "Working on table #{table.name} ..."
      table.provision_throughput(:read_capacity_units => read_capacity_units, :write_capacity_units => write_capacity_units)
      sleep 1 while table.status == :updating
    rescue AWS::DynamoDB::Errors::ValidationException
      # ignore exceptions that are thrown when the requested value equals the current value
    end
    puts "Table: #{table.name} - r/w: #{old_read_capacity_units}/#{old_write_capacity_units} => #{table.read_capacity_units}/#{table.write_capacity_units}"
  end
end
thread_list.map(&:join)

