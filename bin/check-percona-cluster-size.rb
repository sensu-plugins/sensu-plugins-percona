#!/usr/bin/env ruby
#
# Percona Cluster Size Plugin
# ===
#
# This plugin checks the number of servers in the Percona cluster and warns you according to specified limits
#
# Copyright 2012 Chris Alexander <chris.alexander@import.io>, import.io
# Based on the MySQL Health Plugin by Panagiotis Papadomitsos
#
# Depends on mysql:
# gem install mysql2
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'mysql2'
require 'inifile'

class CheckPerconaClusterSize < Sensu::Plugin::Check::CLI
  option :user,
         description: 'MySQL User',
         short: '-u USER',
         long: '--user USER',
         default: 'root'

  option :password,
         description: 'MySQL Password',
         short: '-p PASS',
         long: '--password PASS'

  option :hostname,
         description: 'Hostname to login to',
         short: '-h HOST',
         long: '--hostname HOST',
         default: 'localhost'
  
  option :socket,
         description: 'Socket to connect to',
         short: '-s SOCKET',
         long: '--socket SOCKET',
         default: '/var/lib/mysql/mysql.sock'

  option :expected,
         description: 'Number of servers expected in the cluster',
         short: '-e NUMBER',
         long: '--expected NUMBER',
         default: 1

  option :ini,
         description: 'ini file',
         short: '-i',
         long: '--ini VALUE'

  def run
    if config[:ini]
      update_config
    end
    db = Mysql2::Client.new(
      host:     config[:hostname],
      username: config[:user],
      password: config[:password],
      database: config[:database],
      socket:   config[:socket]
    )
    cluster_size = db.query("SHOW GLOBAL STATUS LIKE 'wsrep_cluster_size'").first['Value'].to_i
    critical "Expected to find #{config[:expected]} nodes, found #{cluster_size}" if cluster_size != config[:expected].to_i
    ok "Expected to find #{config[:expected]} nodes and found those #{cluster_size}" if cluster_size == config[:expected].to_i
  rescue Mysql2::Error => e
    critical "Percona MySQL check failed: #{e.error}"
  ensure
    db.close if db
  end

  def update_config
    ini = IniFile.load(config[:ini])
    section = ini['client']
    section.each do |key, option|
      config[key.to_sym] = option
    end
  end
end
