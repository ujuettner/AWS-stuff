#!/usr/bin/env ruby
#
# This script gathers some information about EC2 instances.
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
options[:region] = ''
option_parser.on('-r', '--region REGION',
  "query just the specified region (default: query all regions)") do |r|
  options[:region] = r
end
option_parser.parse!

exit 1 unless aws_config(options[:aws_config_file])
ec2 = AWS::EC2.new

if options[:region].empty?
  region_list = ec2.regions.map(&:name)
else
  region_list = [options[:region]]
end
puts "Region list: #{region_list.join(' ')}."
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
    image = ec2.regions[region].images[instance.image_id]
    if image.exists?
      puts "\t\t#{image.description} (#{image.architecture}, #{image.virtualization_type}@#{image.hypervisor})"
    else
      puts "\t\tNo image information found."
    end
  end
end
