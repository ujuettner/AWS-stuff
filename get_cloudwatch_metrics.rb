#!/usr/bin/env ruby
#
# This script ...
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

statistics_types = ['Average', 'Maximum', 'Minimum', 'Samples', 'Sum']

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options]"

  options[:aws_config_file] = './aws_config.yml'
  opts.on('-c', '--aws-config FILENAME',
    "AWS config file (default: #{options[:aws_config_file]})") do |c|
    options[:aws_config_file] = c
  end

  options[:namespace] = 'Test/Test'
  opts.on('-n', '--namespace NAMESPACE',
    "metrics namespace (default: #{options[:namespace]})") do |n|
    options[:namespace] = n
  end

  options[:dimension_name] = 'Test'
  opts.on('-d', '--dimension-name DIMENSION_NAME',
    "name of the dimension to use (default: #{options[:dimension_name]})") do |dn|
    options[:dimension_name] = dn
  end

  options[:dimension_value] = 'Test'
  opts.on('-v', '--dimension-value DIMENSION_VALUE',
    "value of the dimension to use (default: #{options[:dimension_value]})") do |dv|
    options[:dimension_value] = dv
  end

  options[:metric_name] = 'Test'
  opts.on('-m', '--metric-name METRIC_NAME',
    "name of the metric to query (default: #{options[:metric_name]})") do |m|
    options[:metric_name] = m
  end

  options[:statistics_type] = 'Average'
  opts.on('-t', '--statistics-type TYPE',
    "statistics type (possible values: #{statistics_types.join(', ')}) (default: #{options[:statistics_type]})") do |t|
    options[:statistics_type] = t
  end

  options[:seconds_back] = 3600
  opts.on('-b', '--seconds-back SECONDS', OptionParser::DecimalNumeric,
    "set the metric query start time to the given number of seconds before now (default: #{options[:seconds_back]})") do |s|
    options[:seconds_back] = s
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

start_time = Time.now.utc - options[:seconds_back]
end_time = Time.now.utc

unless statistics_types.include?(options[:statistics_type])
  puts "Statistics type #{options[:statistics_type]} not supported - use one of the following: #{statistics_types.join(', ')}."
  exit 1
end

puts "Namespace: #{options[:namespace]}"
puts "Dimension name: #{options[:dimension_name]}"
puts "Dimension value: #{options[:dimension_value]}"
puts "Metric name: #{options[:metric_name]}"
puts "Statistics type: #{options[:statistics_type]}"
puts "Start time: #{start_time}"
puts "End time: #{end_time}"

cw = AWS::CloudWatch.new

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
