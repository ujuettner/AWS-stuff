#!/usr/bin/env ruby
#
# This script terminates SWF workflow executions in a given domain.
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
options[:domain] = 'my-domain'
option_parser.on('-d', '--domain DOMAIN',
  "SWF domain (default: #{options[:domain]})") do |d|
  options[:domain] = d
end
option_parser.parse!

exit 1 unless aws_config(options[:aws_config_file])

swf = AWS::SimpleWorkflow.new

puts "Domain: #{options[:domain]}"

domain = swf.domains[options[:domain]]

deleted_workflows = 0
domain.workflow_executions.each do |wf_execution|
  begin
    wf_id = wf_execution.workflow_id
    print "Terminating workflow execution of #{wf_id}..."
    wf_execution.terminate(options = {:child_policy => :terminate})
    puts 'done.'
    deleted_workflows += 1
  rescue Exception
    puts 'Got an exception - ignoring it.'
  end
end
puts "Terminated workflow executions in domain #{options[:domain]}: #{deleted_workflows}"
