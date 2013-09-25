require 'jasmine'
require 'jasmine/runners/selenium'
require 'selenium-webdriver'

Jasmine.configure do |config|
  filepath = File.join(Dir.pwd, 'spec', 'javascripts', 'support', 'jasmine_selenium_runner.yml')
  runner_config = YAML::load(ERB.new(File.read(filepath)).result(binding)) if File.exist?(filepath)
  runner_config ||= {}
  config.port = 5555 if runner_config['use_sauce'] #Sauce only proxies certain ports

  config.runner = lambda { |formatter, jasmine_server_url|
    webdriver = nil
    browser = runner_config.fetch('browser', 'firefox')

    if runner_config['use_sauce']
      sauce_config = runner_config['sauce']

      unless sauce_config['tunnel_identifier']
        require 'sauce/connect'
        Sauce::Connect.connect!
      end

      username = sauce_config.fetch('username')
      key = sauce_config.fetch('access_key')
      driver_url = "http://#{username}:#{key}@localhost:4445/wd/hub"

      capabilities = {
        :name => sauce_config['name'],
        :platform => sauce_config['os'],
        :version => sauce_config['browser_version'],
        :build => sauce_config['build'],
        :tags => sauce_config['tags'],
        :browserName => browser,
        'tunnel-identifier' => sauce_config['tunnel_identifier']
      }

      webdriver = Selenium::WebDriver.for :remote, :url => driver_url, :desired_capabilities => capabilities
    else
      webdriver = Selenium::WebDriver.for(browser.to_sym, {})
    end

    #TODO: re-add firefox firebug profile option
    # if browser == 'firefox-firebug'
    # require File.join(File.dirname(__FILE__), 'firebug/firebug')
    # (profile = Selenium::WebDriver::Firefox::Profile.new)
    # profile.enable_firebug
    # {:profile => profile}
    # else
    #TODO: re-add custom selenium server support
    # elsif selenium_server
    # ::Selenium::WebDriver.for :remote, :url => selenium_server, :desired_capabilities => browser.to_sym
    # else

    Jasmine::Runners::Selenium.new(formatter, jasmine_server_url, webdriver, runner_config.fetch('batch_config_size', 50))
  }
end
