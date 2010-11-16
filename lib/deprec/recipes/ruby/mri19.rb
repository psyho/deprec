# Copyright 2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 

  namespace :deprec do
    namespace :mri19 do
            
      SRC_PACKAGES[:mri19] = {
        :md5sum => "755aba44607c580fddc25e7c89260460  ruby-1.9.2-p0.tar.gz", 
        :url => "ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p0.tar.gz",
      }
  
      desc "Install Ruby"
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:mri19], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:mri19], src_dir)
        top.deprec.rubygems.install
      end
      
      task :install_deps do
        apt.install( {:base => %w(zlib1g-dev libssl-dev libncurses5-dev libreadline5-dev)}, :stable )
      end

    end
  end
end
