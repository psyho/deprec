# Copyright 2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :deprec_tools do
      desc "failing task"
      task :failing_task do
        run "false"
      end
    end if ENV['DUMMY']
    
    [ :dummy1, :dummy2, :dummy3, :dummy4, :dummy5 ].each do |ns|
      namespace ns do
        [ :install, :config_gen, :config, :start, :stop, :restart, :reload, :activate, :deactivate, :backup, :restore ].each do |tsk|
          desc "#{tsk} #{ns}"
          task tsk do
            puts "#{tsk} #{ns}"
          end
        end
      end
    end if ENV['DUMMY']
  end
end