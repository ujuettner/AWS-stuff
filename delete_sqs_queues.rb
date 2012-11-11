#!/usr/bin/env ruby
#
# This script deletes a batch of SQS queues that match a given prefix and are
# older than a given timestamp.
#
# The AWS SDK for Ruby is required. See https://aws.amazon.com/sdkforruby/ for
# installation instructions.
#
# AWS account keys are loaded from a YAML file which has the following format:
# access_key_id: <your access key id>
# secret_access_key: <your secret access key>
#

require 'date'
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

  options[:queue_prefix] = 'my-queue'
  opts.on('-p', '--queue-prefix PREFIX',
    "SQS queue prefix (default: #{options[:queue_prefix]})") do |p|
    options[:queue_prefix] = p
  end

  options[:reference_time] = (Time.now. - 60*60*24).to_s
  opts.on('-t', '--reference-time TIMESTAMP',
    "Reference time, delete queues older than that (default: #{options[:reference_time]})") do |t|
    options[:reference_time] = t
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

puts "Queue prefix: #{options[:queue_prefix]}"
puts "Reference time: #{options[:reference_time]}"

reference_timestamp = DateTime.strptime(options[:reference_time],
                                        '%Y-%m-%d %H:%M:%S %z')

sqs = AWS::SQS.new

deleted_queues = 0
sqs.queues.with_prefix(options[:queue_prefix]).each_batch do |queue_batch|
  puts "About to process #{queue_batch.size} queues ..."
  queue_batch.each do |queue|
    queue.inspect
    if !queue.nil? and !queue.url.nil? and queue.exists?
      q_last_modified_timestamp = queue.last_modified_timestamp
      if q_last_modified_timestamp < reference_timestamp.to_time
        print "Deleting #{queue.url} (last modified at #{queue.last_modified_timestamp})..."
        queue.delete
        deleted_queues += 1
        puts 'done.'
      end
    end
  end
end
puts "Deleted queues matching the critera: #{deleted_queues}."
puts "Criteria:\n\tQueue prefix: #{options[:queue_prefix]}\n\tLast modified before: #{reference_timestamp.to_s}"
