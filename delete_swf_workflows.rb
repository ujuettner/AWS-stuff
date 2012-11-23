#!/usr/bin/env ruby
#
# This script gathers some information about CEC2 instances..
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

  options[:domain] = 'my-domain'
  opts.on('-d', '--domain DOMAIN',
    "SWF domain (default: #{options[:domain]})") do |d|
    options[:domain] = d
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

puts "Domain: #{options[:domain]}."

swf = AWS::SimpleWorkflow.new

domain = swf.domains[options[:domain]]

deleted_workflows = 0
domain.workflow_executions.each do |wf_execution|
  wf_id = wf_execution.workflow_id
  print "Terminating workflow execution of #{wf_id}..."
  wf_execution.terminate(options = {:child_policy => :terminate})
  puts 'done.'
  deleted_workflows += 1
end
puts "Terminated workflow executions in domain #{options[:domain]}: #{deleted_workflows}."
