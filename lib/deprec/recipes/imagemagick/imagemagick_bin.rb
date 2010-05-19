# Copyright 2009-2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :imagemagick_bin do
      
      set :imagemagick_include_rmagick, false
      
      desc "Install imagemagick & rmagick"
      task :install, :roles => :app do
        uninstall # make sure package is uninstalled (if there is any), before attempting source uninstall, since source
                  # uninstall would also remove binary package files
        top.deprec.imagemagick_src.uninstall
        apt.install( {:base => %w(imagemagick libmagick9-dev libmagick10)}, :stable )
        gem2.install 'rmagick' if imagemagick_include_rmagick
      end
      
      task :uninstall, :roles => :app do
        gem2.uninstall 'rmagick' if imagemagick_include_rmagick
        apt.install( {:base => %w(imagemagick- libmagick9-dev- libmagick10-)}, :stable )
      end

    end
  end
end