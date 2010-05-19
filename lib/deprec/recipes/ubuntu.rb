# Copyright 2006-2010 by Mike Bailey, le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :ubuntu do

      set :ubuntu_default_term, :linux
      set :ubuntu_packages_to_install, %w(cron nmap nano bind9-host man-db screen dnsutils iptraf apache2-utils makepasswd psmisc)

      desc "apt-get update. Resynchronize the package index files from their sources."
      task :update do
        apt.update
      end
      
      desc "Install useful ubuntu packages"
      task :install do
        apt.install( {:base => ubuntu_packages_to_install}, :stable )
      end
      
      desc "apt-get upgrade. Install the newest versions of all packages currently
                 installed on the system from the sources enumerated in /etc/apt/sources.list.."
      task :upgrade do
        apt.upgrade
      end

      desc "reboot the server"
      task :restart do
        sudo "reboot"
      end
      
      desc "shut down the server"
      task :shutdown do
        sudo "shutdown -h now"
      end
      
      desc "Remove locks from aborted apt-get command."
      task :remove_locks do
        sudo "rm /var/lib/apt/lists/lock"
        # XXX There's one more - add it!
      end
      
      namespace :utils do
        
        namespace :bash do
          
          task :config do
            deprec2.append_to_file_if_missing('/etc/profile', "export TERM=#{ubuntu_default_term}")
            deprec2.append_to_file_if_missing('/etc/profile', "export RAILS_ENV=#{rails_env}")
          end
          
        end
        
        namespace :cron do
          
          desc "List installed global crons"
          task :list do
            sudo "ls /etc/cron.d"
          end

          desc "Remove all installed global crons"
          task :remove_all do
            sudo "rm -f /etc/cron.d/*"
          end
          
        end
        
        namespace :sys do
          
          desc "View memstats"
          task :free do
            run "free"
          end
          
          desc "Identify servers affected"
          task :ident do
            run "hostname"
          end
          
          desc "Show server IP addresses"
          task :ip do
            run "{ sudo ip addr show dev eth0 | grep inet | grep -v inet6 ; sudo ip addr show dev peth0 | grep inet | grep -v inet6 ; }"
          end
          
        end
        
        
      end
      
    end
  end
end
