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

  options[:region] = ''
  opts.on('-r', '--region REGION',
    "query just the specified region (default: query all regions)") do |r|
    options[:region] = r
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

ec2 = AWS::EC2.new

if options[:region].empty?
  region_list = ec2.regions.map(&:name)
else
  region_list = [options[:region]]
end
puts "Region list: #{region_list.join(' ')}"
region_list.each do |region|
  puts "Region #{region}:"
  ec2.regions[region].instances.each do |instance|
    status = instance.status
    color_sequence = case status
                     when :running then "\033[32m"                              # green
                     when :pending, :shutting_down, :stopping then "\033[33m"   # yellow
                     when :terminated, :stopped then "\033[31m"                 # red
                     else "\033[0m"
                     end
    puts "\t#{instance.id} (DNS: #{instance.dns_name}, IP: #{instance.ip_address}): #{color_sequence}#{status}\033[0m"
    image = ec2.images[instance.image_id]
    if image.exists?
      puts "\t\t#{image.description} (#{image.architecture}, #{image.virtualization_type}@#{image.hypervisor})"
    else
      puts "\t\tNo image information found."
    end
  end
end
