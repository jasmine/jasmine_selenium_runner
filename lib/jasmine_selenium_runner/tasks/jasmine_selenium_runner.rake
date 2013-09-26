namespace :jasmine_selenium_runner do
  task :setup do
    require File.join('jasmine_selenium_runner', 'configure_jasmine')
  end
end

task 'jasmine:require' => ['jasmine_selenium_runner:setup']
