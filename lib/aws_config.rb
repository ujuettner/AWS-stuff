require 'optparse'
require 'yaml'
require 'aws-sdk'



def add_default_options(options)
  option_parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename($0)} [options]"

    options[:aws_config_file] = './aws_config.yml'
    opts.on('-c', '--aws-config FILENAME',
      "AWS config file (default: #{options[:aws_config_file]})") do |c|
      options[:aws_config_file] = c
    end
  end
end

def aws_config(aws_config_file)
  puts "Using #{aws_config_file}."
  unless File.exist?(aws_config_file)
    puts "#{aws_config_file} does not exist!"
    return false
  end
  aws_config = YAML.load(File.read(aws_config_file))
  AWS.config(aws_config)
end
