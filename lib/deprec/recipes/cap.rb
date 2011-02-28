# Copyright 2009-2010 by le1t0@github. All rights reserved.

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deprec do
    namespace :cap do

      desc "Show Capistrano variables"
      task :vars do
        y variables
      end

      desc "Identify which servers are going to be touched, by which user"
      task :ident do
        run 'whoami'
        run 'ifconfig eth0 | grep "inet addr" | cut -d ":" -f 2 | cut -d " " -f 1'
      end

    end
  end
end

