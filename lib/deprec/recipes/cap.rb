# Copyright 2009-2010 by le1t0@github. All rights reserved.

# might be used in other scripts as well for checking differences with deployed configs for example
# (if someone edited server configs by mistake, instead of editing inside the project)
def compare_files(local_file, remote_file)
  tmp_file = File.join('/', 'tmp', "capistrano_compare_#{Time.now.strftime("%Y%m%d%H%M%S")}.tmp")
  File.open(tmp_file, 'w') do |f|
    run "cat #{remote_file}" do |channel, stream, data|
      f.write(data)
    end
  end

  puts `diff #{local_file} #{tmp_file} && echo "files are the same!"`
  FileUtils.rm_f(tmp_file)
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deprec do
    namespace :cap do

      task :compare do
        compare_files(ENV["LOCAL"], ENV["REMOTE"])
      end
      
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

