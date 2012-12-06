#!/usr/bin/env ruby
#
# This script plays around with DynamoDB (creating tables, storing items,
# querying etc.)
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
option_parser.parse!

exit 1 unless aws_config(options[:aws_config_file])

db = AWS::DynamoDB.new
tables = {}

reads_per_second = 10
writes_per_second = 5
{
  "tweets" => {
    :hash_key => {:user_id => :string},
    :range_key => {:created_at => :number}
  },
  "users" => {
    :hash_key => {:id => :string}
  }
}.each_pair do |table_name, schema|
  begin
    tables[table_name] = db.tables[table_name].load_schema
  rescue AWS::DynamoDB::Errors::ResourceNotFoundException
    table = db.tables.create(
      table_name,
      reads_per_second,
      writes_per_second,
      schema
    )
    print "Creating table #{table_name}..."
    sleep 1 while table.status == :creating
    puts 'done!'
    tables[table_name] = table.load_schema
  end
end

10.times do |number|
  current_user = "User#{number}"
  if tables['users'].items.at(current_user).exists?
    puts "Item #{current_user} already exists."
  else
    tables['users'].items.create(:id => current_user)
    puts "Item #{current_user} created."
  end
end

tables['users'].items.each do |user|
  puts "item attributes as hash: #{user.attributes.to_h}"
end
user_three = tables['users'].items.at('User3')
user_five = tables['users'].items.at('User5')
user_three.attributes.add(:following => ['User5'])
user_five.attributes.add(:followers => ['User3', 'User1'])

now = Time.now
user_five.attributes['followers'].each do |follower|
  tables['tweets'].items.create(
    :user_id => tables['users'].items.at(follower).attributes[:id],
    :created_at => now.to_i,
    :text => "This is the tweet text from #{user_five.attributes['id']}."
  )
end

['users', 'tweets'].each do |table_name|
  items_count = tables[table_name].items.count
  puts "Table #{table_name} has #{items_count} items."
end

tables['tweets'].items.query(
  :hash_value => 'User1',
  :range_value => DateTime.now.prev_day.to_time.to_i..Time.now.to_i,
  :select => [:created_at, :text]
).each do |item|
  puts "#{Time.at(item.attributes['created_at'])}: #{item.attributes['text']}"
end

tables['users'].items.each do |item|
  puts "id: #{item.attributes['id']}"
end

WAIT_SECS = 20
print "Waiting #{WAIT_SECS} seconds before deleting the tables"
WAIT_SECS.times do |elasped_secs|
  sleep 1
  print '.'
end
puts 'going on.'

['users', 'tweets'].each do |table_name|
  tables[table_name].delete
  print "Deleting table #{table_name}..."
  begin
    sleep 1 while tables[table_name].status == :deleting
  rescue AWS::DynamoDB::Errors::ResourceNotFoundException
    puts 'done!'
  end
end
