require 'jasmine'
require 'jasmine/runners/selenium'
Jasmine.configure do |config|
  config.runner = lambda { |formatter, jasmine_server_url|
    Jasmine::Runners::Selenium.new(formatter, jasmine_server_url, config)
  }
end
