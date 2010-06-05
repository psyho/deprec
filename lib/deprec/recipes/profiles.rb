# Copyright 2009-2010 by le1t0@github. All rights reserved.

# A little bit about profiles.. What I wanted to achieve was having a list of tasks which I can run,
# which install a server from bare install to fully functional with only one deprec call. Before,
# I fixed this by writing pages and pages of capistrano tasks performing each step, installing,
# configuring and activating all that was needed and for all different configurations. I really
# didn't like this as it was a nightmare to maintain. So I knew I wanted something that very compactly
# can describe the steps to take to fully install a server.
# 
# I had no idea what to name it, I based my ideas on the notion of tasks in the debian linux distribution, but 
# since the word task is already taken in capistrano, I just went for the word profile :) So a profile is 
# basically an ordered list of recipes to run, including which tasks to perform on them; furthermore, a 
# profile can reference other profiles, so you can extract out generic definitions. I defined
# [ :config_gen, :install, :config, :activate, :start ] to be the default list of tasks to perform on a recipe,
# but made it possible to override this list per profile (for example when you want to make profiles which can
# give you a status overview of the entire server farm or something).. Each profile would mention only the name
# of a recipe to run, and possibly (as arguments) the list of tasks to include this recipe for. So when a profile
# should run in the 5 mentioned tasks, and you add recipe imagemagick with as an argument :install, then it would
# only run install on the imagemagick recipe. Finally, I added the option of calling a custom task (i.e. not one
# of the 5 default ones). Some examples:
# 
# profile :tools, :install do |p, r| # only execute the :install task on the include recipes in this profile
#   r.ubuntu
#   r.nagios_plugins
#   r.imagemagick
#   r.aspell
# end
# 
# profile :base do |p, r|    # the 'p' object allows you to call other profiles, the 'r' object allows you to call recipes
#   r.iptables
#   r.postfix
#   r.ntp
#   r.ubuntu.utils.bash :config # call :config in utils.bash namespace of ubuntu recipe
#   p.tools # include another profile in this profile
# end
# 
# profile :app_base do |p, r| # this profile, as most others, doesn't define a custom set of tasks, so it runs  [ :config_gen, :install, :config, :activate, :start ] 
#   r.call.passenger.config_gen_system :config_gen
#   r.call.rails.install_stack :install # run custom task :install_stack during the :install phase on the rails recipe; use call to define calling a custom task
#   r.java
# end
# 
# profile :db_base do |p, r|
#   r.mysql
#   r.sphinx :install # only execute :install for sphinx, for the others run the defaults ([ :config_gen, :install, :config, :activate, :start ])
#   r.java
# end
# 
# profile :composite_server do |p, r| # make a profile purely based on other profiles
#   p.base
#   p.app_base
#   p.db_base
# end

Capistrano::Configuration.instance(:must_exist).load do 
  class DeprecProfile
    # list of profiles or recipes to call for this profile
    attr_accessor :tasks_to_call
    # keep track the current called profile/recipe. We can't add them directly to :tasks_to_call, because we need to support
    # (namespace) nested tasks and literal tasks as well.
    attr_accessor :current_task
    # boolean which states whether we are in the sub namespace of a recipe or just the base recipe
    attr_accessor :sub_namespace
    # if we want to call another task than the default for a certain step (i.e. calling :install_all_my_stuff instead
    # of just :install for the install step) this variable (boolean) tells us whether this is the case
    attr_accessor :literal

    def initialize
      # by default, we have no profiles/recipes defined and we don't start out in a sub_namespace
      @tasks_to_call = []
      @sub_namespace = false
    end
    
    def call
      # only support calling literal tasks when we are not in a sub_namespace
      if !@sub_namespace
        # since method_missing won't be called now, we need to call finalize, before continuing
        finalize
        @literal = true # can't set directly in :current_task, since it will run finalize again in method_missing then (wrongly)
      end
      self
    end
    
    # the very core of the profiles code, which implements the DSL for defining profiles and recipes to call
    def method_missing(method_name, *args, &block)
      obj = nil
      # if we are not in a sub_namespace, then this is a base recipe or profile to call
      if !@sub_namespace
        # call finalize, so any previous current_task gets registered
        finalize
        # make sure we start out fresh
        @current_task ||= {}
        # if we want to call a literal task, define it now in the :current_task variable, and reset the literal variable
        # for next tasks to come
        @current_task[:literal] = true if @literal
        @literal = false
        # define the name of the recipe or profile to call
        @current_task[:name] = method_name.to_s
        # define any arguments as well, which could be a list of symbols overriding (only_recipe_tasks) below. Use this
        # when you want a certain recipe or profile to only execute for one or more certain steps. I.e. when the entire
        # profile executes for :install and :config steps, but you want imagemagick to only execute for the :install step,
        # you would use this.
        @current_task[:args] = args.size == 0 ? nil : args.flatten
        # return a copy of ourselves, since we don't want to contaminate the current one with the sub_namespace setting,
        # as we can never set it to false anymore (no way to detect it)
        obj = self.dup
        obj.sub_namespace = true
      else
        # we are in a sub_namespace, so define the sub_namespace name by concatting it to the existing name with a dot
        @current_task[:name] = [ @current_task[:name], method_name.to_s ].join('.')
        # register any arguments as well
        @current_task[:args] = args.size == 0 ? nil : args.flatten
        # return our self, so we can also go into another sub_namespace
        obj = self
      end
      obj
    end
    
    def finalize
      # if a current task is defined, make sure it gets registered in :tasks_to_call and reset :current_task,
      # for a possible next call
      if !@current_task.nil?
        @tasks_to_call << @current_task
        @current_task = nil
      end
    end
  end

  # define a profile, with arguments
  # - a name for the resulting task which executes the profile
  # - optionally an array of (or just one) symbol(s) of task names to execute (by default) within the recipes
  # contained in this profile
  # - a block containing calls to either other profiles or recipes
  def profile(profile_task_name, *only_recipe_tasks, &block)
    only_recipe_tasks = [ :config_gen, :install, :config, :activate, :start ] if only_recipe_tasks.size == 0
    # Execute the block with two arguments, the first will contain profiles which should be called, the second
    # will contain recipes which should be called
    yield(profiles = DeprecProfile.new, recipes = DeprecProfile.new)
    profiles.finalize
    recipes.finalize
    # define a list of distclean tasks which remove all stamps for the respective profile for either all step tasks
    # (only_recipe_tasks) or one of these
    ([ :all ] + only_recipe_tasks).each do |tsk|
      cmd = "
        namespace :deprec do\nnamespace :profiles do\nnamespace :#{profile_task_name} do\nnamespace :distclean do\ndesc '#{profile_task_name}:distclean:#{tsk}'\ntask :#{tsk} do\n
        remove_profile_stamps('#{profile_task_name}:#{tsk}')\nend\nend\nend\nend\nend
      "
      puts cmd if ENV['DEBUG_PROFILES']
      eval(cmd)
    end
    # define the :all task for the profile, which calls all tasks defined in (only_recipe_tasks) on the profile itself, and
    # stamps its success. Remove all stamps when successful
    cmd = "
      namespace :deprec do\nnamespace :profiles do\nnamespace :#{profile_task_name} do\ndesc '#{profile_task_name}:all'\ntask :all do\n
        #{only_recipe_tasks.collect do |n|
          "unless profile_stamp_exists?('#{profile_task_name}:all', '#{profile_task_name}', '#{n}') ; then
             top.deprec.profiles.#{profile_task_name}.#{n}
             profile_stamp('#{profile_task_name}:all', '#{profile_task_name}', '#{n}')
           end
          " end.join("\n")}\n
      remove_profile_stamps('#{profile_task_name}:all')\nend\nend\nend\nend
    "
    puts cmd if ENV['DEBUG_PROFILES']
    eval(cmd)
    # define the various tasks defined in (only_recipe_tasks) for this profile, they should call their respective step task
    # on the profiles and recipes contained within this profile, and stamp their success. Remove all stamps if everything
    # was successful
    only_recipe_tasks.each do |rt|
      cmd = "
        desc '#{profile_task_name}:#{rt}'\nnamespace :deprec do\nnamespace :profiles do\nnamespace :#{profile_task_name} do\ntask :#{rt} do\n
          #{profiles.tasks_to_call.collect do |tsk|
            (tsk[:args] || only_recipe_tasks).include?(rt) ?
              "unless profile_stamp_exists?('#{profile_task_name}:#{rt}', '#{tsk[:name]}', '#{rt}') ; then
                 top.deprec.profiles.#{tsk[:name]}.#{rt}
                 profile_stamp('#{profile_task_name}:#{rt}', '#{tsk[:name]}', '#{rt}')
               end
              " : ""
            end.join("\n")}\n
          #{recipes.tasks_to_call.collect do |tsk|
            (tsk[:args] || only_recipe_tasks).include?(rt) ?
              "unless profile_stamp_exists?('#{profile_task_name}:#{rt}', '#{tsk[:name]}', '#{rt}') ; then
                 #{tsk[:literal] ? "top.deprec.#{tsk[:name]}" : "top.deprec.#{tsk[:name]}.#{rt}"}
                 profile_stamp('#{profile_task_name}:#{rt}', '#{tsk[:name]}', '#{rt}')
               end
              " : ""
            end.join("\n")}\n
        remove_profile_stamps('#{profile_task_name}:#{rt}')\nend\nend\nend\nend
      "
      puts cmd if ENV['DEBUG_PROFILES']
      eval(cmd)
    end
  end
  
  # create a stamp for the currently executed profile, the recipe that has been completed and specifically which task
  # has been run on it
  def profile_stamp(profile_name, executing_recipe, executing_task)
    stamp_name = "stamp-#{profile_name.gsub(/:/, '_')}-#{executing_task_name(executing_recipe, executing_task)}"
    run "mkdir -p ~/.deprec ; touch ~/.deprec/#{stamp_name}"
  end

  # check whether a stamp already exists
  def profile_stamp_exists?(profile_name, executing_recipe, executing_task)
    stamp_name = "stamp-#{profile_name.gsub(/:/, '_')}-#{executing_task_name(executing_recipe, executing_task)}"
    result = nil
    run "mkdir -p ~/.deprec ; test -e ~/.deprec/#{stamp_name} && echo OK || true" do |channel,stream,data|
      result = (data.strip == "OK")
    end
    result
  end
  
  # remove all stamps for a profile
  def remove_profile_stamps(profile_name)
    run "mkdir -p ~/.deprec ; rm -f ~/.deprec/stamp-#{profile_name.gsub(/:/, '_')}-*"
  end
  
  # helper method for the stamp and stamp_exists? methods above
  def executing_task_name(executing_recipe, executing_task)
    if executing_recipe =~ /\./
      "#{executing_recipe.gsub(/\./, '_')}--#{executing_task}"
    else
      "#{executing_recipe}_#{executing_task}"
    end
  end
end
