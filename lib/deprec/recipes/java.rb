# Copyright 2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :java do
      
      set :java_include_jdk, false
      
      desc "Install Java"
      task :install do
        packages = %w(sun-java6-bin sun-java6-jre)
        packages << "sun-java6-jdk" if java_include_jdk
        apt.install( {:base => packages}, :stable )
      end
      
      desc "Config java"
      task :config do
        deprec2.append_to_file_if_missing('/etc/profile', 'export JAVA_HOME=/usr/lib/jvm/java-6-sun')
        deprec2.append_to_file_if_missing('/etc/profile', 'export PATH=$PATH:${JAVA_HOME}/bin')
      end
            
    end
  end
end