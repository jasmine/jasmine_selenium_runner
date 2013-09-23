require 'jasmine'
require 'jasmine/runners/selenium'
Jasmine.configure do |config|
  config.runner = Jasmine::Runners::Selenium
end
