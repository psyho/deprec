unless Capistrano::Configuration.respond_to?(:instance)
  abort "deprec2 requires Capistrano 2"
end

require "#{File.dirname(__FILE__)}/deprec/capistrano_extensions"
require "#{File.dirname(__FILE__)}/vmbuilder_plugins/all"
require "#{File.dirname(__FILE__)}/deprec/recipes"

Capistrano::Configuration.instance.namespace :deprec do
  namespace :deprec do
    task :config_compare do
      abort "You have to specify the template of configs to compare with TEMPLATE=\"mysql\"" unless ENV['TEMPLATE']
      top.deprec.deprec.config_compare_project
      top.deprec.deprec.config_compare_system
    end

    task :config_compare_project do
      abort "You have to specify the template of configs to compare with TEMPLATE=\"mysql\"" unless ENV['TEMPLATE']
      deprec2.push_configs(ENV['TEMPLATE'].to_s.to_sym, PROJECT_CONFIG_FILES[ENV['TEMPLATE'].to_s.to_sym], true) if PROJECT_CONFIG_FILES[ENV['TEMPLATE'].to_s.to_sym]
    end

    task :config_compare_system do
      abort "You have to specify the template of configs to compare with TEMPLATE=\"mysql\"" unless ENV['TEMPLATE']
      deprec2.push_configs(ENV['TEMPLATE'].to_s.to_sym, SYSTEM_CONFIG_FILES[ENV['TEMPLATE'].to_s.to_sym], true) if SYSTEM_CONFIG_FILES[ENV['TEMPLATE'].to_s.to_sym]
    end
  end
end
