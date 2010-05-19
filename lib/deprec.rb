unless Capistrano::Configuration.respond_to?(:instance)
  abort "deprec2 requires Capistrano 2"
end

require "#{File.dirname(__FILE__)}/deprec/capistrano_extensions"
require "#{File.dirname(__FILE__)}/vmbuilder_plugins/all"
require "#{File.dirname(__FILE__)}/deprec/recipes"

# The below: Copyright 2009-2010 by le1t0@github. All rights reserved.
# add missing standard tasks to the various namespaces, so generic scripts won't break, the standard tasks are for now:
standard_tasks = [
  :install,
  :config_gen,
  :config_project_gen,
  :config_system_gen,
  :config,
  :config_project,
  :config_system,
  :start,
  :stop,
  :restart,
  :reload,
  :activate,
  :deactivate,
  :backup,
  :restore,
  :status
]
Capistrano::Configuration.instance.deprec.namespaces.keys.each do |ns_name|
  ns = Capistrano::Configuration.instance.deprec.send(ns_name)
  standard_tasks.each do |standard_task|
    unless ns.respond_to?(standard_task)
      Capistrano::Configuration.instance.namespace :deprec do
        namespace ns_name do
          task standard_task do
            # nothing to be done here
          end
        end
      end
    end
  end
end