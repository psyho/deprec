# Copyright 2009-2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :iptables do

      set :iptables_allowed, "tcp:22,80,443"
      set :iptables_forwards, ""
      set :iptables_binary, "/sbin/iptables"
      set :iptables_save_binary, "/sbin/iptables-save"

      task :status do
        sudo "iptables -L -v"
      end

      desc "Install iptables"
      task :install do
        install_deps
      end

      task :install_deps do
        apt.install( {:base => %w(iptables)}, :stable )
      end

      SYSTEM_CONFIG_FILES[:iptables] = [

        {:template => 'firewall-init.erb',
          :path => '/etc/init.d/firewall',
          :mode => 0755,
          :owner => 'root:root'},
        {:template => 'firewall-default.erb',
          :path => '/etc/default/firewall',
          :mode => 0755,
          :owner => 'root:root'}
      ]

      desc "Generate iptables config from template."
      task :config_gen do
        SYSTEM_CONFIG_FILES[:iptables].each do |file|
          deprec2.render_template(:iptables, file)
        end
      end

      desc "Push iptables config files to server"
      task :config do
        sudo "test -e /etc/default/firewall && cp /etc/default/firewall /etc/default/firewall.bak || true"
        sudo "test -e /etc/init.d/firewall && cp /etc/init.d/firewall /etc/init.d/firewall.bak || true"
        deprec2.push_configs(:iptables, SYSTEM_CONFIG_FILES[:iptables])
        deprec2.append_to_file_if_missing('/etc/services', 'vrrp           112/raw                          # vrrpd daemon')
      end

      desc "Generate new iptables configs, upload them and restart iptables, revert if failing"
      task :reconfig do
        transaction do
          on_rollback {
            puts `git checkout config/#{stage}/iptables/etc`
            sudo "test -e /etc/default/firewall.bak && mv /etc/default/firewall.bak /etc/default/firewall || true"
            sudo "test -e /etc/init.d/firewall.bak && mv /etc/init.d/firewall.bak /etc/init.d/firewall || true"
            sudo "/etc/init.d/firewall start &"
          }
          config_gen
          config
          restart
        end
        activate
      end
      
      desc "Revert iptables config on server"
      task :revert do
        sudo "test -e /etc/default/firewall.bak && mv /etc/default/firewall.bak /etc/default/firewall || true"
        sudo "test -e /etc/init.d/firewall.bak && mv /etc/init.d/firewall.bak /etc/init.d/firewall || true"
      end

      desc 'Enable iptables start scripts on server.'
      task :activate do
        send(run_method, "update-rc.d firewall start 99 S .")
      end

      desc 'Disable iptables start scripts on server.'
      task :deactivate do
        send(run_method, "update-rc.d -f firewall remove")
      end

      desc "Start iptables"
      task :start do
        send(run_method, "/etc/init.d/firewall start &")
      end

      desc "Restart iptables"
      task :restart do
        send(run_method, "/etc/init.d/firewall start &")
      end
    end 
  end
end