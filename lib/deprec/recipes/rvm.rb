# Copyright 2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :rvm do
      
      RVM_VERSION='1.0.1'
      
      set :rvm_apt_packages, []
      set :rvm_rubies, [] # First ruby will be set as default if rvm_default_ruby is nil or empty
      set :rvm_default_ruby, nil
      set :rvm_support_jruby, false
      set :rvm_support_ree, false
      set :rvm_support_mri, false
      set :rvm_support_rbx, false
      set :rvm_support_ironruby, false
      
      desc "Install Rvm"
      task :install do
        install_deps
        install_rvm = true
        run "rvm --version | perl -n -e 'm/^rvm / && s/^rvm ([^ ]+) .*/$1/ && print'" do |channel, stream, data|
          install_rvm = false if data.strip == RVM_VERSION
        end
        if install_rvm
          run "mkdir -p ~/.rvm/src/"
          run "cd ~/.rvm/src/ && rm -Rf rvm-#{RVM_VERSION} && wget -O /dev/stdout -o /dev/null http://rvm.beginrescueend.com/releases/rvm-#{RVM_VERSION}.tar.gz | tar zxf -"
          run "cd ~/.rvm/src/rvm-#{RVM_VERSION} && ./install"
          run "perl -p -i -e 's/^([^#]+&& return.*)/#$1/' ~/.bashrc"
          sudo <<-END
          sh -c '
          grep -F "[[ -s \\$HOME/.rvm/scripts/rvm ]] && source \\$HOME/.rvm/scripts/rvm" ~/.bashrc > /dev/null 2>&1 || 
          echo "[[ -s \\$HOME/.rvm/scripts/rvm ]] && source \\$HOME/.rvm/scripts/rvm" >> ~/.bashrc
          '
          END
        end
        install_rubies
      end
      
      task :install_deps do
        top.deprec.mri.install_deps
        apt_packages = rvm_apt_packages.dup
        apt_packages += %w(build-essential bison openssl libreadline5 libreadline-dev curl git-core zlib1g zlib1g-dev libssl-dev vim libsqlite3-0 libsqlite3-dev sqlite3 libreadline-dev libxml2-dev git-core subversion autoconf patch) if rvm_support_mri || rvm_support_ree
        apt_packages += %w(curl sun-java6-bin sun-java6-jre sun-java6-jdk) if rvm_support_jruby
        apt_packages += %w(curl mono-2.0-devel) if rvm_support_ironruby
        apt_packages.uniq!
        apt.install( {:base => apt_packages}, :stable )
      end
      
      desc "Install rubies"
      task :install_rubies do
        rubies = rvm_rubies.dup
        rubies ||= []
        rubies.unshift('ruby-1.8.7-p160') if rubies.empty? || rvm_support_rbx
        rubies.uniq!
        rubies.each_with_index do |ruby_def, i|
          ruby = ruby_def.is_a?(Hash) ? ruby_def.keys.first : ruby_def
          env_opts = ""
          configure_opts = ""
          ruby_arch = ruby_def.is_a?(Hash) ? ruby_def.values.first : nil
          if ruby_arch == "i386"
            env_opts = "CFLAGS='-m32' CXXFLAGS='-m32' LDFLAGS='-m32' "
            configure_opts = "--configure --host=i686-pc-linux,--target=i686-pc-linux,--build=i686-pc-linux"
          end
          run "#{env_opts}rvm --reconfigure #{configure_opts} --force install #{ruby}"
          run "rvm --default #{ruby} --passenger" if i == 0 && (rvm_default_ruby.nil? || rvm_default_ruby.empty?)
        end
        if !(rvm_default_ruby.nil? || rvm_default_ruby.empty?)
          set_default = rvm_default_ruby == "system" ? rvm_default_ruby : "--default #{rvm_default_ruby}"
          run "rvm #{set_default} --passenger"
        end
      end
      
    end
  end
end