require 'bundler/setup'
Bundler.require

require 'prometheus/client/data_stores/direct_file_store'
Prometheus::Client.config.data_store =
  Prometheus::Client::DataStores::DirectFileStore.new(dir: File.expand_path('../tmp', __dir__))

require File.expand_path('tasks/application_task.rb', __dir__);
Dir[File.expand_path('../tasks/**/*_task.rb', __dir__)].each { |task| require task }

Tasks.constants.each do |task_class|
  Tasks.const_get(task_class).new.register
end
