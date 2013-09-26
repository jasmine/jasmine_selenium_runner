require 'rails/railtie'

module JasmineSeleniumRunner
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'jasmine_selenium_runner/tasks/jasmine_selenium_runner.rake'
    end
  end
end

