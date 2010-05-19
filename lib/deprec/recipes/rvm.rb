# Copyright 2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :rvm do
      
      set :rvm_rubies, %w(ruby-1.8.7-p160) # First ruby will be set as default if rvm_default_ruby is nil or empty
      set :rvm_default_ruby, nil
      
      desc "Install Rvm"
      task :install do
        run <<-EOF
        version=$(curl http://rvm.beginrescueend.com/releases/stable-version.txt) ;
        mkdir -p ~/.rvm/src/ && curl -O http://rvm.beginrescueend.com/releases/rvm-${version}.tar.gz | tar zxf - && cd rvm-${version} && ./install
        
EOF
      end
      
      desc "Install rubies"
      task :install_rubies do
        rvm_rubies.each_with_index do |ruby, i|
          run "rvm install #{ruby}"
          run "rvm --default #{ruby}" if i == 0 && (rvm_default_ruby.empty? || rvm_default_ruby.nil?)
        end
        if !(rvm_default_ruby.empty? || rvm_default_ruby.nil?)
          set_default = rvm_default_ruby == "system" ? rvm_default_ruby : "--default #{rvm_default_ruby}"
          run "rvm #{set_default}"
        end
      end
      
    end
  end
end