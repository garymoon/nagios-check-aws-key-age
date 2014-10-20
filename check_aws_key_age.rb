#!/usr/bin/env ruby
require 'rubygems'
require 'aws-sdk'
require 'optparse'

EXIT_CODES = {
  :unknown => 3,
  :critical => 2,
  :warning => 1,
  :ok => 0
}

options =
{
  :debug => false,
  :months => 12,
  :exceptions => []
}

config = { }

opt_parser = OptionParser.new do |opt|

  opt.on("--exceptions username[,username]","which usernames do you wish to exclude?") do |exceptions|
    options[:exceptions] = exceptions.split(',')
  end

  opt.on("--months months","how many months old can a key be?") do |months|
    options[:months] = months
  end

  opt.on("-k","--key key","specify your AWS key ID") do |key|
    (config[:access_key_id] = key) unless key.empty?
  end

  opt.on("-s","--secret secret","specify your AWS secret") do |secret|
    (config[:secret_access_key] = secret) unless secret.empty?
  end
  
  opt.on("--debug","enable debug mode") do
    options[:debug] = true
  end

  opt.on("-h","--help","help") do
    puts opt_parser
    exit
  end
end

opt_parser.parse!

raise OptionParser::MissingArgument, 'Missing "--secret" or "--key"' if (options[:key] ^ !options[:secret])

if (options[:debug])
  puts 'Options: '+options.inspect
  puts 'Config: '+config.inspect
end

begin

  AWS.config(config)
  iam = AWS::IAM.new

  max_age = Date.today << options[:months]

  failed_keys = []

  iam.users.each do |user|
    if (options[:exceptions].include? user.name) then next end
    username = user.name
    puts username if options[:debug]
    user.access_keys.each do |key|
      puts "#{key.id}: #{key.create_date.to_date.to_s}" if options[:debug]
      if (((key.create_date.to_date - max_age).to_i < 0) && (key.active?))
        failed_keys << key.id + " (" + username + ")"
      end
    end
  end

  if (failed_keys.size > 0)
    puts "CRIT: There are #{failed_keys.length} active keys older than #{options[:months]} months: "
    puts failed_keys.join("\n")
    exit EXIT_CODES[:critical]
  end

rescue SystemExit
  raise

rescue Exception => e
  puts 'CRIT: Unexpected error: ' + e.message + ' <' + e.backtrace[0] + '>'
  exit EXIT_CODES[:critical]

end

puts "OK: No users with outdated keys found."
exit EXIT_CODES[:ok]
