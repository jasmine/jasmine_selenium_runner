require 'jasmine'
require 'jasmine/runners/selenium'
require 'selenium-webdriver'

Jasmine.configure do |config|
  config.runner = lambda { |formatter, jasmine_server_url|
    filepath = File.join(Dir.pwd, 'spec', 'javascripts', 'support', 'jasmine_selenium_runner.yml')
    runner_config = YAML::load(ERB.new(File.read(filepath)).result(binding)) if File.exist?(filepath)
    runner_config ||= {}

    webdriver = nil

    if runner_config['use_sauce']

      # unless runner_config['tunnel_identifier']
        require 'sauce/connect'
        Sauce::Connect.connect!
      # end

      username = runner_config.fetch('sauce_username')
      key = runner_config.fetch('sauce_access_key')
      # platform = ENV['SAUCE_PLATFORM']
      # version = ENV['SAUCE_VERSION']
      url = "http://#{username}:#{key}@localhost:4445/wd/hub"
      config.port = 5555

      capabilities = {
        # :platform => platform,
        # :version => version,
        # :build => ENV['TRAVIS_BUILD_NUMBER'],
        # :tags => [ENV['TRAVIS_RUBY_VERSION'], 'CI'],
        :browserName =>  'firefox' #runner_config.fetch('browser', 'firefox')
      }

      # capabilities.merge!('tunnel-identifier' => ENV['TRAVIS_JOB_NUMBER']) if ENV['TRAVIS_JOB_NUMBER']
      webdriver = Selenium::WebDriver.for :remote, :url => url, :desired_capabilities => capabilities
    else
      webdriver = Selenium::WebDriver.for(:firefox, {})
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

    Jasmine::Runners::Selenium.new(formatter, jasmine_server_url, webdriver, 50) #TODO: runner_config.fetch('batch_config_size', 50)
  }
end
