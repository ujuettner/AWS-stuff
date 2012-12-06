#!/usr/bin/env ruby
#
# This script gets data points out of CloudWatch.
#
# The AWS SDK for Ruby is required. See https://aws.amazon.com/sdkforruby/ for
# installation instructions.
#
# AWS account keys are loaded from a YAML file which has the following format:
# access_key_id: <your access key id>
# secret_access_key: <your secret access key>
#

require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'aws_config'))

statistics_types = ['Average', 'Maximum', 'Minimum', 'Samples', 'Sum']

options = {}
option_parser = add_default_options(options)
options[:namespace] = 'Test/Test'
option_parser.on('-n', '--namespace NAMESPACE',
  "metrics namespace (default: #{options[:namespace]})") do |n|
  options[:namespace] = n
end
options[:dimension_name] = 'Test'
option_parser.on('-d', '--dimension-name DIMENSION_NAME',
  "name of the dimension to use (default: #{options[:dimension_name]})") do |dn|
  options[:dimension_name] = dn
end
options[:dimension_value] = 'Test'
option_parser.on('-v', '--dimension-value DIMENSION_VALUE',
  "value of the dimension to use (default: #{options[:dimension_value]})") do |dv|
  options[:dimension_value] = dv
end
options[:metric_name] = 'Test'
option_parser.on('-m', '--metric-name METRIC_NAME',
  "name of the metric to query (default: #{options[:metric_name]})") do |m|
  options[:metric_name] = m
end
options[:statistics_type] = 'Average'
option_parser.on('-t', '--statistics-type TYPE',
  "statistics type (possible values: #{statistics_types.join(', ')}) (default: #{options[:statistics_type]})") do |t|
  options[:statistics_type] = t
end
options[:seconds_back] = 3600
option_parser.on('-b', '--seconds-back SECONDS', OptionParser::DecimalNumeric,
  "set the metric query start time to the given number of seconds before now (default: #{options[:seconds_back]})") do |s|
  options[:seconds_back] = s
end
option_parser.parse!

exit 1 unless aws_config(options[:aws_config_file])

start_time = Time.now.utc - options[:seconds_back]
end_time = Time.now.utc

unless statistics_types.include?(options[:statistics_type])
  puts "Statistics type #{options[:statistics_type]} not supported - use one of the following: #{statistics_types.join(', ')}."
  exit 1
end

cw = AWS::CloudWatch.new

puts "Namespace: #{options[:namespace]}"
puts "Dimension name: #{options[:dimension_name]}"
puts "Dimension value: #{options[:dimension_value]}"
puts "Metric name: #{options[:metric_name]}"
puts "Statistics type: #{options[:statistics_type]}"
puts "Start time: #{start_time}"
puts "End time: #{end_time}"

metrics = cw.metrics.with_namespace(options[:namespace])
filtered_metrics = metrics.with_dimension(options[:dimension_name], options[:dimension_value]).with_metric_name(options[:metric_name])
filtered_metrics.each do |metric|
  stats = metric.statistics(:start_time => start_time,
                            :end_time => end_time,
                            :statistics => [options[:statistics_type]])
  if !stats.metric.dimensions.empty? and stats.first
    dimensions_info = stats.metric.dimensions.map{|dim| "#{dim[:name]} => #{dim[:value]}" }.join(', ')
    puts "#{stats.metric.namespace} | #{dimensions_info} | #{stats.metric.metric_name}:"
    stats.sort{|a, b| a[:timestamp] <=> b[:timestamp]}.each do |datapoint|
      puts "\t#{datapoint}"
    end
  end
end
