# Copyright 2006-2010 by Mike Bailey, le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :ssh do
      
      # hash of :user => :ssh_key combinations
      # :ssh_*_keys can be:
      # - one key (a string)
      # - an array of keys
      set :ssh_user_keys, { }
      set :ssh_host_keys, { }
      # an array of symbols or strings containing user_names/host_names as defined in :ssh_*_keys
      set :ssh_users, [ ]
      set :ssh_hosts, [ ]

      SYSTEM_CONFIG_FILES[:ssh] = [
        
        {:template => "sshd_config.erb",
         :path => '/etc/ssh/sshd_config',
         :mode => 0644,
         :owner => 'root:root'},
         
        {:template => "ssh_config.erb",
         :path => '/etc/ssh/ssh_config',
         :mode => 0644,
         :owner => 'root:root'}
      ]
      
      task :config_gen do        
        SYSTEM_CONFIG_FILES[:ssh].each do |file|
          deprec2.render_template(:ssh, file)
        end
        auth_keys_dir = 'config/ssh/authorized_keys'
        if ! File.directory?(auth_keys_dir)
          puts "Creating #{auth_keys_dir}"
          Dir.mkdir(auth_keys_dir)
        end
      end
      
      desc "Push ssh config files to server"
      task :config do
        deprec2.push_configs(:ssh, SYSTEM_CONFIG_FILES[:ssh])
        restart
      end

      task :set_access do
        if ssh_users.size > 0
          run "rm -f ~/.ssh/authorized_keys.new"
          ssh_users.each do |ssh_user|
            keys = [ssh_user_keys[ssh_user]].flatten
            keys.each do |ssh_key|
              deprec2.append_to_file_if_missing('~/.ssh/authorized_keys.new', ssh_key)
            end
          end
          run "cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.bak"
          run "mv ~/.ssh/authorized_keys.new ~/.ssh/authorized_keys"
        end

        if ssh_hosts.size > 0
          run "rm -f ~/.ssh/known_hosts.new"
          ssh_hosts.each do |ssh_user|
            keys = [ssh_host_keys[ssh_user]].flatten
            keys.each do |ssh_key|
              deprec2.append_to_file_if_missing('~/.ssh/known_hosts.new', ssh_key)
            end
          end
          run "cp ~/.ssh/known_hosts ~/.ssh/known_hosts.bak"
          run "mv ~/.ssh/known_hosts.new ~/.ssh/known_hosts"
        end
      end
      
      desc "Start ssh"
      task :start do
        send(run_method, "/etc/init.d/ssh reload")
      end
    
      desc "Stop ssh"
      task :stop do
        send(run_method, "/etc/init.d/ssh reload")
      end
    
      desc "Restart ssh"
      task :restart do
        send(run_method, "/etc/init.d/ssh restart")
      end
    
      desc "Reload ssh"
      task :reload do
        send(run_method, "/etc/init.d/ssh reload")
      end
      
      desc "Sets up authorized_keys file on remote server"
      task :setup_keys do
        
        default(:target_user) { 
          Capistrano::CLI.ui.ask "Setup keys for which user?" do |q|
            q.default = user
          end
        }
        
        # If we have an authorized keys file for this user
        # then copy that out
        if File.exists?("config/ssh/authorized_keys/#{target_user}") 
          deprec2.mkdir "/home/#{target_user}/.ssh", :mode => 0700, :owner => "#{target_user}.users", :via => :sudo
          std.su_put File.read("config/ssh/authorized_keys/#{target_user}"), "/home/#{target_user}/.ssh/authorized_keys", '/tmp/', :mode => 0600
          sudo "chown #{target_user}.users /home/#{target_user}/.ssh/authorized_keys"
        
        elsif target_user == user
          
          # If the user has specified a key Capistrano should use
          if ssh_options[:keys]
            deprec2.mkdir '.ssh', :mode => 0700
            put(ssh_options[:keys].collect{|key| File.read("#{key}.pub")}.join("\n"), '.ssh/authorized_keys', :mode => 0600 )
          
          # Try to find the current users public key
          elsif keys = %w[id_rsa id_dsa identity].collect { |f| "#{ENV['HOME']}/.ssh/#{f}.pub" if File.exists?("#{ENV['HOME']}/.ssh/#{f}.pub") }.compact
            deprec2.mkdir '.ssh', :mode => 0700
            put(keys.collect{|key| File.read(key)}.join("\n"), '.ssh/authorized_keys', :mode => 0600 )
            
          else
            puts <<-ERROR

            You need to define the name of your SSH key(s)
            e.g. ssh_options[:keys] = %w(/Users/your_username/.ssh/id_rsa)

            You can put this in your .caprc file in your home directory.

            ERROR
            exit
          end
        else
          puts <<-ERROR
          
          Could not find ssh public key(s) for user #{user}
          
          Please create file containing ssh public keys in:
          
            config/ssh/authorized_keys/#{target_user}
            
          ERROR
        end
        
      end
      
    end
  end
end