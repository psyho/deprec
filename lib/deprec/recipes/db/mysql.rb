# Copyright 2006-2010 by Mike Bailey, le1t0@github. All rights reserved.

def run_mysql_command(command, user = "root", password = nil, database=nil)
  database = database.nil? ? "" : " #{database}"
  password = password.nil? ? "" : " -p #{password}"
  run "echo \"#{command}\" | mysql -u #{user} #{password} #{database}"
end

Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :mysql do
      
      set :mysql_client_port, 3306
      set :mysql_client_socket, '/var/run/mysqld/mysqld.sock'
      
      set :mysql_mysql_no_auto_rehash, false # faster start of mysql but no tab completion
      
      set :mysql_mysqld_safe_socket, '/var/run/mysqld/mysqld.sock'
      set :mysql_mysqld_safe_nice, 0
      
      set :mysql_mysqldump_max_allowed_packet, '16M'
      set :mysql_mysqldump_quote_names, true
      set :mysql_mysqldump_quick, true
      
      set :mysql_isamchk_key_buffer, '16M'
      set :mysql_isamchk_sort_buffer_size, nil
      set :mysql_isamchk_read_buffer, nil
      set :mysql_isamchk_write_buffer, nil

      set :mysql_myisamchk_key_buffer, nil
      set :mysql_myisamchk_sort_buffer_size, nil
      set :mysql_myisamchk_read_buffer, nil
      set :mysql_myisamchk_write_buffer, nil
      
      set :mysql_mysqld_innodb_force_recovery, nil # needed when recovering from innodb and parts can be saved
      set :mysql_mysqld_user, 'mysql'
      set :mysql_mysqld_pid_file, '/var/run/mysqld/mysqld.pid'
      set :mysql_mysqld_socket, '/var/run/mysqld/mysqld.sock'
      set :mysql_mysqld_port, 3306
      set :mysql_mysqld_basedir, '/usr'
      set :mysql_mysqld_datadir, '/var/lib/mysql'
      set :mysql_mysqld_tmpdir, '/tmp'
      set :mysql_mysqld_language, '/usr/share/mysql/english'
      set :mysql_mysqld_default_storage_engine, nil
      set :mysql_mysqld_skip_external_locking, true
      set :mysql_mysqld_skip_bdb, true
      set :mysql_mysqld_skip_innodb, false
      set :mysql_mysqld_bind_address, '127.0.0.1'
      
      set :mysql_mysqld_default_character_set, nil
      set :mysql_mysqld_character_set_server, nil
      set :mysql_mysqld_collation_server, nil
      set :mysql_mysqld_group_concat_max_len, nil
      set :mysql_mysqld_innodb_file_per_table, false

      # this should be smaller than RAM:
      # innodb_buffer_pool_size + key_buffer_size + max_connections*(sort_buffer_size+read_buffer_size+binlog_cache_size) + max_connections*2MB      
      set :mysql_mysqld_thread_cache_size, 8
      set :mysql_mysqld_thread_stack, '128K'
      set :mysql_mysqld_max_allowed_packet, '16M'
      set :mysql_mysqld_table_cache, 64
      set :mysql_mysqld_innodb_log_buffer_size, nil
      set :mysql_mysqld_innodb_additional_mem_pool_size, nil
      set :mysql_mysqld_innodb_flush_method, nil
      set :mysql_mysqld_thread_concurrency, nil
      set :mysql_mysqld_max_connections, nil
      set :mysql_mysqld_read_buffer_size, nil
      set :mysql_mysqld_read_rnd_buffer_size, nil
      set :mysql_mysqld_sort_buffer_size, nil
      set :mysql_mysqld_innodb_buffer_pool_size, nil
      set :mysql_mysqld_key_buffer, '16M'
      set :mysql_mysqld_query_cache_limit, '1M'
      set :mysql_mysqld_query_cache_size, '16M'
      set :mysql_mysqld_query_cache_type, nil
      set :mysql_mysqld_tmp_table_size, nil
      set :mysql_mysqld_max_heap_table_size, nil
      set :mysql_mysqld_innodb_log_file_size, nil

      set :mysql_mysqld_ssl_ca, nil
      set :mysql_mysqld_ssl_cert, nil
      set :mysql_mysqld_ssl_key, nil
      
      set :mysql_mysqld_server_id, nil
      set :mysql_mysqld_auto_increment_increment, nil
      set :mysql_mysqld_auto_increment_offset, nil
      set :mysql_mysqld_master_host, nil
      set :mysql_mysqld_master_user, nil
      set :mysql_mysqld_master_password, nil
      set :mysql_mysqld_report_host, nil
      set :mysql_mysqld_replicate_wild_ignore_table, nil
      
      set :mysql_mysqld_log, nil # i.e. /var/log/mysql/mysql.log
      set :mysql_mysqld_binlog_do_db, nil # i.e. include_database_name
      set :mysql_mysqld_binlog_ignore_db, nil # i.e. include_database_name
      set :mysql_mysqld_log_bin, '/var/log/mysql/mysql-bin.log'
      set :mysql_mysqld_relay_log, nil
      set :mysql_mysqld_relay_log_info_file, nil
      set :mysql_mysqld_relay_log_index, nil
      set :mysql_mysqld_expire_logs_days, 10
      set :mysql_mysqld_max_binlog_size, '1024M'
      set :mysql_mysqld_log_slow_queries, nil
      set :mysql_mysqld_long_query_time, nil
      set :mysql_mysqld_log_slave_updates, false
      set :mysql_mysqld_log_queries_not_using_indexes, false
      
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
