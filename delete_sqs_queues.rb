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

require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'aws_config'))

options = {}
option_parser = add_default_options(options)
options[:queue_prefix] = 'my-queue'
option_parser.on('-p', '--queue-prefix PREFIX',
  "SQS queue prefix (default: #{options[:queue_prefix]})") do |p|
  options[:queue_prefix] = p
end
options[:reference_time] = (Time.now. - 60*60*24).to_s
option_parser.on('-t', '--reference-time TIMESTAMP',
  "reference time, delete queues older than that (default: #{options[:reference_time]})") do |t|
  options[:reference_time] = t
end
option_parser.parse!

exit 1 unless aws_config(options[:aws_config_file])

sqs = AWS::SQS.new

puts "Queue prefix: #{options[:queue_prefix]}"
puts "Reference time: #{options[:reference_time]}"

reference_timestamp = DateTime.strptime(options[:reference_time],
                                        '%Y-%m-%d %H:%M:%S %z')

deleted_queues_per_batch = 0
sum_deleted_queues = 0
begin
  deleted_queues_per_batch = 0
  sqs.queues.with_prefix(options[:queue_prefix]).each_batch do |queue_batch|
    puts "About to process #{queue_batch.size} queues in this batch ..."
    queue_batch.each do |queue|
      if !queue.nil? and !queue.url.nil? and queue.exists?
        q_last_modified_timestamp = queue.last_modified_timestamp
        if q_last_modified_timestamp < reference_timestamp.to_time
          print "Deleting #{queue.url} (last modified at #{queue.last_modified_timestamp})..."
          queue.delete
          deleted_queues_per_batch += 1
          puts 'done.'
        end
      end
      puts "#{deleted_queues_per_batch} queues deleted in this batch up to now." if deleted_queues_per_batch % 50 == 0
    end
  end
  puts "Totally deleted queues in this batch: #{deleted_queues_per_batch}"
  sum_deleted_queues += deleted_queues_per_batch
end until deleted_queues_per_batch == 0
puts "Totally deleted queues matching the critera in all batches: #{sum_deleted_queues}"
puts "Criteria:\n\tQueue prefix: #{options[:queue_prefix]}\n\tLast modified before: #{reference_timestamp.to_s}"
