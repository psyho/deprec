# Copyright 2006-2010 by Mike Bailey, le1t0@github. All rights reserved.
unless Capistrano::Configuration.respond_to?(:instance)
  abort "deprec2 requires Capistrano 2"
end

# manually loading all recipes is cumbersome and leads to a lot of conflicts when merging branches.
# I rewrote this file so recipes get loaded automatically. Only files mentioned in the dependencies list and all
# files ending in .rb get loaded, so rename them to prevent them being loaded (as I did with some based on the
# old code)

# Loading is done as follows:
# - define a dependencies list
# - from that list, derive a load order
# - load the rest of the recipes to the end of the load order list
# - require all recipes mentioned in the load order list in the order that they are mentioned

def load_recipe_names(base_dir, prefix = '')
  recipes = []
  Dir.new(base_dir).entries.each do |entry|
    next if [ ".", "..", "rails" ].include?(entry)
    fqn = File.join(base_dir, entry)
    if File.directory?(fqn)
      recipes += load_recipe_names(fqn, "#{prefix}#{entry}/")
    elsif fqn =~ /\.rb$/
      recipes << "#{prefix}#{entry.gsub(/\.rb$/, '')}"
    end
  end
  recipes
end

def order_dependencies(&block)
  copy_of_dependencies = {}
  # load defined dependencies + make values of type array if they aren't + add entries for non-mentioned dependencies
  # themselves
  yield().each do |recipe, dependencies|
    copy_of_dependencies[recipe.to_s] = [dependencies].flatten.collect { |dependency| dependency.to_s }
    copy_of_dependencies[recipe.to_s].each do |dependency|
      copy_of_dependencies[dependency] = [] if copy_of_dependencies[dependency].nil?
    end
  end
  recipies_load_order = []

  # define load order for all depended upon recipes
  offset = 0
  while copy_of_dependencies.keys.size > 0 do
    current = copy_of_dependencies.keys[offset]
    if current.nil? && offset > 0
      offset -= 1
      next
    end
    raise "cannot find recipe #{current}.rb in the filesystem!" if !File.exist?("#{File.dirname(__FILE__)}/recipes/#{current}.rb")
    dependencies = copy_of_dependencies[current]
    if dependencies.size == 0 || dependencies.all? { |dependency| recipies_load_order.include?(dependency) }
      recipies_load_order << current
      copy_of_dependencies.delete(current)
    else
      offset = (offset + 1) % copy_of_dependencies.keys.size
    end
  end
  
  load_recipe_names("#{File.dirname(__FILE__)}/recipes/").each do |recipe|
    recipies_load_order << recipe unless recipies_load_order.include?(recipe)
  end
  
  recipies_load_order
end

recipies_load_order = order_dependencies do
  # key is the recipe to load, value is the recipe that should be loaded earlier already
  # value can be an array (to denote multiple dependencies), but doesn't have to be
  # TODO: cleanup and minimize number of dependencies.
  # NOTE: this is only needed to define a load order. If one recipe is needed to be loaded
  # before all others, just mention it by itself with an empty array dependencies list, since
  # all other recipes are loaded after the recipes mentioned here.
  # NOTE2: internally the dependencies processor works with strings, but we can specify using
  # symbols here
  {
    :deprec => :canonical,
    :deprecated => :deprec,
    :chef => :deprecated,
    :"app/mongrel" => :chef,
    :"app/passenger" => :"app/mongrel",
    :"db/mysql" => :"app/passenger",
    :"db/postgresql" => :"db/mysql",
    :"db/sqlite" => :"db/postgresql",
    :"db/couchdb" => :"db/sqlite",
    :"ruby/mri" => :"db/couchdb",
    :"ruby/ree" => :"ruby/mri",
    :"web/apache" => :"ruby/ree",
    :"web/nginx" => :"web/apache",
    :git => :"web/nginx",
    :svn => :git,
    :integrity => :svn,
    :users => :integrity,
    :ssh => :users,
    :php => :ssh,
    :aoe => :php,
    :xen => :aoe,
    :xentools => :xen,
    :ddclient => :xentools,
    :ntp => :ddclient,
    :logrotate => :ntp,
    :ssl => :logrotate,
    :postfix => :ssl,
    :memcache => :postfix,
    :monit => :memcache,
    :network => :monit,
    :nagios => :network,
    :collectd => :nagios,
    :syslog => :collectd,
    :heartbeat => :syslog,
    :haproxy => :heartbeat,
    :ubuntu => :haproxy,
    :lvm => :ubuntu,
    :vnstat => :lvm,
    :utils => :vnstat,
    :wpmu => :utils,
    :ar_sendmail => :wpmu,
    :starling => :ar_sendmail
  }
end

recipies_load_order.each do |recipe|
  require "#{File.dirname(__FILE__)}/recipes/#{recipe}"
end