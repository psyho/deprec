# Copyright 2009-2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  class DeprecProfile
    attr_accessor :tasks_to_call
    attr_accessor :current_task
    attr_accessor :sub_namespace
    attr_accessor :literal

    def initialize
      @tasks_to_call = []
      @sub_namespace = false
    end
    
    def call
      if !@sub_namespace
        finalize
        @literal = true # can't set directly in current_task, since it will run finalize again in method_missing then (wrongly)
      end
      self
    end
    
    def method_missing(method_name, *args, &block)
      obj = nil
      if !@sub_namespace
        finalize
        @current_task ||= {}
        @current_task[:literal] = true if @literal
        @literal = false
        @current_task[:name] = method_name.to_s
        @current_task[:args] = args.size == 0 ? nil : args.flatten
        obj = self.dup
        obj.sub_namespace = true
      else
        @current_task[:name] = [ @current_task[:name], method_name.to_s ].join('.')
        @current_task[:args] = args.size == 0 ? nil : args.flatten        
        obj = self
      end
      obj
    end
    
    def finalize
      if !@current_task.nil?
        @tasks_to_call << @current_task
        @current_task = nil
      end
    end
  end

  def profile(profile_task_name, *only_recipe_tasks, &block)
    only_recipe_tasks = [ :config_gen, :install, :config, :activate, :start ] if only_recipe_tasks.size == 0
    yield(profiles = DeprecProfile.new, recipes = DeprecProfile.new)
    profiles.finalize
    recipes.finalize
    ([ :all ] + only_recipe_tasks).each do |tsk|
      cmd = "
        namespace :deprec do\nnamespace :profiles do\nnamespace :#{profile_task_name} do\nnamespace :distclean do\ndesc '#{profile_task_name}:distclean:#{tsk}'\ntask :#{tsk} do\n
        remove_profile_stamps('#{profile_task_name}:#{tsk}')\nend\nend\nend\nend\nend
      "
      puts cmd if ENV['DEBUG_PROFILES']
      eval(cmd)
    end    
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
  
  def profile_stamp(profile_name, executing_recipe, executing_task)
    stamp_name = "stamp-#{profile_name.gsub(/:/, '_')}-#{executing_task_name(executing_recipe, executing_task)}"
    run "mkdir -p ~/.deprec ; touch ~/.deprec/#{stamp_name}"
  end
  
  def profile_stamp_exists?(profile_name, executing_recipe, executing_task)
    stamp_name = "stamp-#{profile_name.gsub(/:/, '_')}-#{executing_task_name(executing_recipe, executing_task)}"
    result = nil
    run "mkdir -p ~/.deprec ; test -e ~/.deprec/#{stamp_name} && echo OK || true" do |channel,stream,data|
      result = (data.strip == "OK")
    end
    result
  end
  
  def remove_profile_stamps(profile_name)
    run "mkdir -p ~/.deprec ; rm -f ~/.deprec/stamp-#{profile_name.gsub(/:/, '_')}-*"
  end
  
  def executing_task_name(executing_recipe, executing_task)
    if executing_recipe =~ /\./
      "#{executing_recipe.gsub(/\./, '_')}--#{executing_task}"
    else
      "#{executing_recipe}_#{executing_task}"
    end
  end
end
