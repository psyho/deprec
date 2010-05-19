# Copyright 2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :redis do
      
      set :redis_user, 'redis'
      set :redis_group, 'redis'
      
      SRC_PACKAGES[:redis] = {
        :md5sum => '0c5355e57606523f9e8ce816db5e542f  redis-1.2.6.tar.gz',
        :filename => 'redis-1.2.6.tar.gz',
        :dir => 'redis-1.2.6',
        :url => "http://redis.googlecode.com/files/redis-1.2.6.tar.gz",
        :unpack => "tar zxf redis-1.2.6.tar.gz;",
        :make => 'make;',
        :configure => nil,
        :install => "install -t /usr/local/bin redis-server redis-benchmark redis-cli redis-stat; install -o #{redis_user} -g #{redis_group} -d /var/lib/redis /var/log/redis"
      }
      
      desc "install Redis"
      task :install do
        create_redis_user
        deprec2.download_src(SRC_PACKAGES[:redis], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:redis], src_dir)
      end
    
      SYSTEM_CONFIG_FILES[:redis] = [
        
        {:template => "redis-init.erb",
         :path => '/etc/init.d/redis',
         :mode => 0755,
         :owner => 'root:root'},

        {:template => "redis-conf.erb",
         :path => '/etc/redis/redis.conf',
         :mode => 0755,
         :owner => 'root:root'}
        
      ]
      
      desc <<-DESC
      Generate redis config from template. Note that this does not
      push the config to the server, it merely generates required
      configuration files. These should be kept under source control.            
      The can be pushed to the server with the :config task.
      DESC
      task :config_gen do
        SYSTEM_CONFIG_FILES[:redis].each do |file|
          deprec2.render_template(:redis, file)
        end
      end

      desc "Push redis config files to server"
      task :config, :roles => :redis do
        deprec2.push_configs(:redis, SYSTEM_CONFIG_FILES[:redis])
      end

      task :create_redis_user, :roles => :redis do
        deprec2.groupadd(redis_group)
        deprec2.useradd(redis_user, :group => redis_group, :homedir => false)
      end

      desc "Start Redis"
      task :start, :roles => :redis do
        send(run_method, "/etc/init.d/redis start")
      end

      desc "Stop Redis"
      task :stop, :roles => :redis do
        send(run_method, "/etc/init.d/redis stop")
      end

      desc "Restart Redis"
      task :restart, :roles => :redis do
        send(run_method, "/etc/init.d/redis restart")
      end

      desc "Set Redis to start on boot"
      task :activate, :roles => :redis do
        send(run_method, "update-rc.d redis defaults")
      end
      
      desc "Set Redis to not start on boot"
      task :deactivate, :roles => :redis do
        send(run_method, "update-rc.d -f redis remove")
      end
      
    end 
  end
end