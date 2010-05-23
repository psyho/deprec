# Copyright 2006-2010 by Mike Bailey, le1t0@github. All rights reserved.
unless Capistrano::Configuration.respond_to?(:instance)
  abort "deprec2 requires Capistrano 2"
end

# manually loading all recipes is cumbersome and leads to a lot of conflicts when merging branches.
# I rewrote this file so recipes get loaded automatically. Only files mentioned in the preload_recipes list and all
# files ending in .rb get loaded, so rename them to prevent them being loaded (as I did with some based on the
# old code)

# Loading is done as follows:
# - preload a couple of recipes in a certain order
# - load all other recipes in directory order

preload_recipes = [ "canonical", "deprec", "deprecated" ]
base_recipes = Dir.glob("#{File.dirname(__FILE__)}/recipes/*.rb").collect do |filename|
  File.basename(filename, '.rb')
end
alternatives_recipes = Dir.glob("#{File.dirname(__FILE__)}/recipes/*/*.rb").collect do |filename|
  "#{File.basename(File.dirname(filename))}/#{File.basename(filename, '.rb')}"
end

(preload_recipes + base_recipes + alternatives_recipes).each do |recipe|
  require "#{File.dirname(__FILE__)}/recipes/#{recipe}"
end
