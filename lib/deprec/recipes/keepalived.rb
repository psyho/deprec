# Copyright 2009-2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :keepalived do
        
      set :keepalived_script, 'killall -0 haproxy'
      set :keepalived_virtual_ipaddress, '192.168.0.99'
      set :keepalived_virtual_router_id, '51'
      set :keepalived_interface, 'eth0'
      set :keepalived_interval, '2'  # check every 2 seconds
      set :keepalived_weight, '2'  # add 2 points of prio if OK
      set :keepalived_priority, '101' # 101 on master, 100 on backup
      set :keepalived_state, 'MASTER'
  
      desc "Install keepalived on server"
      task :install, :roles => :failover do
        install_deps
        update_sysctl
      end
  
      task :install_deps, :roles => :failover do
        apt.install( {:base => %w(keepalived)}, :stable )
      end
  
      SYSTEM_CONFIG_FILES[:keepalived] = [
        {:template => 'keepalived.conf.erb',
         :path => '/etc/keepalived/keepalived.conf',
         :mode => 0644,
         :owner => 'root:root'}
      ]
    
      desc "Generate config files for keepalived"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:keepalived].each do |file|
          deprec2.render_template(:keepalived, file)
        end
      end
  
      desc "Push keepalived config files to server"
      task :config, :roles => :failover do
        deprec2.push_configs(:keepalived, SYSTEM_CONFIG_FILES[:keepalived])
        reactivate
      end
  
      task :update_sysctl, :roles => :failover do
        deprec2.append_to_file_if_missing('/etc/sysctl.conf', 'net.ipv4.ip_nonlocal_bind=1')
        sudo 'sysctl -p'
      end
  
      task :start, :roles => :failover do
        sudo "/etc/init.d/keepalived start"
      end

      task :stop, :roles => :failover do
        sudo "/etc/init.d/keepalived stop"
      end
  
      task :restart do
        stop
        start
      end

      task :activate, :roles => :failover do
        sudo "update-rc.d keepalived start 50 S . stop 9 0 6 ."
      end
  
      task :deactivate, :roles => :failover do
        sudo "update-rc.d -f keepalived remove"
      end
  
      task :reactivate do
        deactivate
        activate
      end
  
    end
  end
end