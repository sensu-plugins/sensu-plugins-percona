#!/usr/bin/env ruby
#
#  check-wsrep-ready
#
# DESCRIPTION:
#   This plugin checks the wsrep_ready status of the cluster.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: mysql2
#
# USAGE:
#
# NOTES:
#   Based on the Percona Cluster Size Plugin by Chris Alexander <chris.alexander@import.io>, import.io; which is based on
#   Based on the MySQL Health Plugin by Panagiotis Papadomitsos
#
# LICENSE:
#   Copyright 2016 Antonio Berrios aberrios@psiclik.plus.com
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'mysql2'
require 'inifile'

class CheckWsrepReady < Sensu::Plugin::Check::CLI
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
    wsrep_ready = db.query("SHOW STATUS LIKE 'wsrep_ready';").first['Value']
    critical "WSREP Ready is not ON. Is #{wsrep_ready}" if wsrep_ready != 'ON'
    ok 'Cluster is OK!' if wsrep_ready == 'ON'
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
