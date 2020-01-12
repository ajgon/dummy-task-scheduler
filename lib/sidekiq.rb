require File.expand_path('./setup.rb', __dir__)

require 'sidekiq-scheduler'


Sidekiq.configure_server do |config|
  config.on(:startup) do
    Tasks.constants.each do |task_class|
      next if task_class == :ApplicationTask
      task_name = task_class.to_s.gsub(/[A-Z]+/) { |letter| "_#{letter.downcase}" }.sub(/^_/, '')
      Sidekiq.set_schedule(task_name, { 'every' => Tasks.const_get(task_class).interval, 'class' => "Tasks::#{task_class}" })
    end

    SidekiqScheduler::Scheduler.instance.reload_schedule!
  end
end


