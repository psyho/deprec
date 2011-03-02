Capistrano::Configuration.instance(:must_exist).load do
  namespace :deprec do
    namespace :beanstalkd do

      set :beanstalkd_user, 'beanstalkd'

      SRC_PACKAGES[:beanstalkd] = {
        :filename => 'beanstalkd-1.4.6.tar.gz',
        :dir => 'beanstalkd-1.4.6',
        :url => "https://github.com/downloads/kr/beanstalkd/beanstalkd-1.4.6.tar.gz",
        :unpack => "tar zxf beanstalkd-1.4.6.tar.gz;",
        :configure => %w(
          ./configure --prefix=/usr
          ;
          ).reject{|arg| arg.match '#'}.join(' '),
        :make => 'make;',
        :install => 'make install;'
      }

      SRC_PACKAGES[:libevent] = {
        :filename => 'libevent-1.4.14b-stable.tar.gz',
        :dir => 'libevent-1.4.14b-stable',
        :url => "http://www.monkey.org/~provos/libevent-1.4.14b-stable.tar.gz",
        :unpack => "tar zxf libevent-1.4.14b-stable.tar.gz;",
        :configure => %w(
          ./configure --prefix=/usr
          ;
          ).reject{|arg| arg.match '#'}.join(' '),
        :make => 'make;',
        :install => 'make install;'
      }

      desc "Install beanstalkd with dependencies"
      task :install do
        install_libevent
        install_beanstalkd
        config_gen
        config
        add_user
        activate
        start
      end

      desc "Install beanstalkd"
      task :install_beanstalkd do
        deprec2.download_src(SRC_PACKAGES[:beanstalkd], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:beanstalkd], src_dir)
      end

      desc "Install libevent"
      task :install_libevent do
        deprec2.download_src(SRC_PACKAGES[:libevent], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:libevent], src_dir)
      end

      SYSTEM_CONFIG_FILES[:beanstalkd] = [
        {:template => 'beanstalkd-init-script',
         :path => '/etc/init.d/beanstalkd',
         :mode => 0755,
         :owner => 'root:root'}
      ]

      task :config_gen do
        SYSTEM_CONFIG_FILES[:beanstalkd].each do |file|
          deprec2.render_template(:beanstalkd, file)
        end
      end

      desc "Push beanstalkd config files to server"
      task :config do
        deprec2.push_configs(:beanstalkd, SYSTEM_CONFIG_FILES[:beanstalkd])
      end

      desc "Add beanstalkd user"
      task :add_user do
        deprec2.useradd(beanstalkd_user, :homedir => false)
      end

      desc "Start beanstalkd"
      task :start do
        send(run_method, "/etc/init.d/beanstalkd start")
      end

      desc "Stop beanstalkd"
      task :stop  do
        send(run_method, "/etc/init.d/beanstalkd stop")
      end

      desc "Restart beanstalkd"
      task :restart  do
        send(run_method, "/etc/init.d/beanstalkd restart")
      end

      desc "Reload beanstalkd"
      task :reload  do
        send(run_method, "/etc/init.d/beanstalkd reload")
      end

      desc <<-DESC
      Activate beanstalkd start scripts on server.
      Setup server to start beanstalkd on boot.
      DESC
      task :activate do
        send(run_method, "update-rc.d beanstalkd defaults")
      end

      desc <<-DESC
      Dectivate beanstalkd start scripts on server.
      Setup server to start beanstalkd on boot.
      DESC
      task :deactivate do
        send(run_method, "update-rc.d -f beanstalkd remove")
      end

    end
  end
end
