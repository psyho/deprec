# Copyright 2006-2010 by Mike Bailey, le1t0@github. All rights reserved.

def run_mysql_command(command, user = "root", password = nil, database=nil)
  database = database.nil? ? "" : " #{database}"
  password = password.nil? ? "" : " -p #{password}"
  run "echo \"#{command}\" | mysql -u #{user} #{password} #{database}"
end

Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :mysql do
      
      set :mysql_admin_user, 'root'
      set(:mysql_admin_pass) { Capistrano::CLI.password_prompt "Enter database password for '#{mysql_admin_user}':"}

      SRC_PACKAGES[:percona_backup] = {
        :filename => 'xtrabackup-1.0.tar.gz',   
        :dir => 'xtrabackup-1.0',  
        :url => "http://www.percona.com/mysql/xtrabackup/1.0/binary/xtrabackup-1.0.tar.gz",
        :unpack => "tar zxf xtrabackup-1.0.tar.gz;",
        :configure => 'echo > /dev/null;',
        :make => 'echo > /dev/null;',
        :install => 'mv /usr/local/src/xtrabackup-1.0/bin/* /usr/local/bin/;'
      }
      
      # Installation
      
      desc "Install mysql"
      task :install, :roles => :db do
        install_deps
        config
        start
        # symlink_mysql_sockfile # XXX still needed?
      end
      
      # Install dependencies for Mysql
      task :install_deps, :roles => :db do
        apt.install( {:base => %w(mysql-server mysql-client libmysqlclient15-dev)}, :stable )
      end
      
      desc "Install percona backup utility"
      task :install_percona_backup, :roles => :db do
        deprec2.download_src(SRC_PACKAGES[:percona_backup], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:percona_backup], src_dir)
      end
      
      # Configuration
      
      SYSTEM_CONFIG_FILES[:mysql] = [
        
        {:template => "my.cnf.erb",
         :path => '/etc/mysql/my.cnf',
         :mode => 0644,
         :owner => 'root:root'}
      ]
      
      desc "Generate configuration file(s) for mysql from template(s)"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:mysql].each do |file|
          deprec2.render_template(:mysql, file)
        end
      end
      
      desc "Push mysql config files to server"
      task :config, :roles => :db do
        deprec2.push_configs(:mysql, SYSTEM_CONFIG_FILES[:mysql])
        reload
      end
      
      task :activate, :roles => :db do
        send(run_method, "update-rc.d mysql defaults")
      end  
      
      task :deactivate, :roles => :db do
        send(run_method, "update-rc.d -f mysql remove")
      end
      
      # Control
      
      desc "Start Mysql"
      task :start, :roles => :db do
        send(run_method, "/etc/init.d/mysql start")
      end
      
      desc "Stop Mysql"
      task :stop, :roles => :db do
        send(run_method, "/etc/init.d/mysql stop")
      end
      
      desc "Restart Mysql"
      task :restart, :roles => :db do
        send(run_method, "/etc/init.d/mysql restart")
      end
      
      desc "Reload Mysql"
      task :reload, :roles => :db do
        send(run_method, "/etc/init.d/mysql reload")
      end
      
      
      task :backup, :roles => :db do
      end
      
      task :restore, :roles => :db do
      end
      
      desc "Create a mysql user"
      task :create_user, :roles => :db do
        # TBA
      end
      
      desc "Create a database" 
      task :create_database, :roles => :db do
        cmd = "CREATE DATABASE IF NOT EXISTS #{db_name}"
        run "mysql -u #{mysql_admin_user} -p -e '#{cmd}'" do |channel, stream, data|
          if data =~ /^Enter password:/
             channel.send_data "#{mysql_admin_pass}\n"
           end
        end       
      end
      
      desc "Grant user access to database" 
      task :grant_user_access_to_database, :roles => :db do        
        cmd = "GRANT ALL PRIVILEGES ON #{db_name}.* TO '#{db_user}'@localhost IDENTIFIED BY '#{db_password}';"
        run "mysql -u #{mysql_admin_user} -p #{db_name} -e \"#{cmd}\"" do |channel, stream, data|
          if data =~ /^Enter password:/
             channel.send_data "#{mysql_admin_pass}\n"
           end
        end
      end
      
      namespace :utils do

        task :show_slave_status, :roles => :db do
          run_mysql_command("SHOW SLAVE STATUS\\G")
        end

        task :show_master_status, :roles => :db do
          run_mysql_command("SHOW MASTER STATUS;")
        end

        task :show_status, :roles => :db do
          run_mysql_command("SHOW STATUS;")
        end

        task :show_variables, :roles => :db do
          run_mysql_command("SHOW VARIABLES;")
        end

        task :show_global_variables, :roles => :db do
          run_mysql_command("SHOW GLOBAL VARIABLES;")
        end

        task :start_slave, :roles => :db do
          run_mysql_command("START SLAVE;")
        end

        task :stop_slave, :roles => :db do
          run_mysql_command("STOP SLAVE;")
        end

      end
            
    end
  end
end

#
# Setup replication
#

# setup user for repl
# GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%.yourdomain.com' IDENTIFIED BY 'slavepass';

# get current position of binlog
# mysql> FLUSH TABLES WITH READ LOCK;
# Query OK, 0 rows affected (0.00 sec)
# 
# mysql> SHOW MASTER STATUS;
# +------------------+----------+--------------+------------------+
# | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
# +------------------+----------+--------------+------------------+
# | mysql-bin.000012 |      296 |              |                  | 
# +------------------+----------+--------------+------------------+
# 1 row in set (0.00 sec)
# 
# # get current data
# mysqldump --all-databases --master-data >dbdump.db
# 
# UNLOCK TABLES;


# Replication Features and Issues
# http://dev.mysql.com/doc/refman/5.0/en/replication-features.html
