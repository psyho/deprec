# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :memcache do
      
      set :memcache_ip, 'INDRR_ANY'
      set :memcache_port, 11211
      set :memcache_memory, 64
      set :memcache_factor, 1.25
      set :memcache_minsize, 48
      set :memcache_conn, 1024
  
      SYSTEM_CONFIG_FILES[:memcache] = [
    
        {:template => "memcache-init.d",
         :path => '/etc/init.d/memcached',
         :mode => 0755,
         :owner => 'root:root'}
     
      ]
  
      task :install, :roles => :memcached do
        version = 'memcached-1.4.5'
        set :src_package, {
          :file => version + '.tar.gz',   
          :md5sum => '583441a25f937360624024f2881e5ea8  memcached-1.4.5.tar.gz', 
          :dir => version,  
          :url => "http://memcached.googlecode.com/files/#{version}.tar.gz",
          :unpack => "tar zxf #{version}.tar.gz;",
          :configure => %w{
            ./configure
            --prefix=/usr/local 
            ;
            }.reject{|arg| arg.match '#'}.join(' '),
          :make => 'make;',
          :install => 'make install;'
        }
        apt.install( {:base => %w(libevent-dev)}, :stable )
        deprec.download_src(src_package, src_dir)
        deprec.install_from_src(src_package, src_dir)
      end
  
      desc "Generate memcached configs"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:memcache].each do |file|
         deprec2.render_template(:memcache, file)
        end
      end

      desc "Push memcached config files (system & project level) to server"
      task :config, :roles => :memcached do
        deprec2.push_configs(:memcache, SYSTEM_CONFIG_FILES[:memcache])
        reload
      end

      desc "Start memcached"
      task :start, :roles => :memcached do
        run "#{sudo} /etc/init.d/memcached start"
      end
  
      desc "Stop memcached"
      task :stop, :roles => :memcached do
        run "#{sudo} /etc/init.d/memcached stop"
      end
  
      desc "Restart memcached"
      task :restart, :roles => :memcached do
        run "#{sudo} /etc/init.d/memcached restart"
      end
  
      desc "Reload memcached"
      task :reload, :roles => :memcached do
        run "#{sudo} /etc/init.d/memcached force-reload"
      end
  
      task :activate, :roles => :memcached do
        run "#{sudo} update-rc.d memcached defaults"
      end  
  
      task :deactivate, :roles => :memcached do
        run "#{sudo} update-rc.d -f memcached remove"
      end
  
    end
  end
end