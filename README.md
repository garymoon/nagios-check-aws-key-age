nagios-check-aws-key-age
========================

A Nagios check for monitoring the age of AWS IAM keys

    Usage: check_aws_key_age [options]
            --exceptions username[,username]
                                         which usernames do you wish to exclude?
            --months months              how many months old can a key be?
        -k, --key key                    specify your AWS key ID
        -s, --secret secret              specify your AWS secret
            --debug                      enable debug mode
        -h, --help                       help

Configuration
-------------

    define command{
      command_name  check_aws_key_age
      command_line  $USER1$/check_aws_key_age.rb --key '$ARG1$' --secret '$ARG2$' --exceptions '$ARG3' --months '$ARG4'
      }
    
    define service{
      use                             generic-service
      host_name                       aws
      service_description             AWS Key Age
      check_command                   check_aws_key_age!<%= @aws_nagios_key %>!<%= @aws_nagios_secret %>!user1,user2!6!
      check_interval                  5
    }

Notes:
* It intentionally excludes all inactive keys.