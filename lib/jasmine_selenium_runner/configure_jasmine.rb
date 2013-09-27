require 'jasmine'
require 'jasmine/runners/selenium'
require 'selenium-webdriver'

module JasmineSeleniumRunner
  class ConfigureJasmine
    def self.install_selenium_runner
      Jasmine.configure do |config|
        runner_config = load_config
        config.port = 5555 if runner_config['use_sauce'] #Sauce only proxies certain ports

        config.runner = lambda { |formatter, jasmine_server_url|
          new(formatter, jasmine_server_url, runner_config).make_runner
        }
      end
    end

    def self.load_config
      filepath = File.join(Dir.pwd, 'spec', 'javascripts', 'support', 'jasmine_selenium_runner.yml')
      if File.exist?(filepath)
        YAML::load(ERB.new(File.read(filepath)).result(binding))
      else
        {}
      end
    end

    def initialize(formatter, jasmine_server_url, runner_config)
      @formatter = formatter
      @jasmine_server_url = jasmine_server_url
      @runner_config = runner_config
      @browser = runner_config['browser'] || 'firefox'
    end

    def make_runner
      webdriver = nil
      if runner_config['use_sauce']
        webdriver = sauce_webdriver(runner_config['sauce'])
      elsif runner_config['selenium_server']
        webdriver = remote_webdriver(runner_config['selenium_server'])
      else
        webdriver = local_webdriver
      end

      Jasmine::Runners::Selenium.new(formatter, jasmine_server_url, webdriver, batch_size)
    end

    def batch_size
      runner_config['batch_config_size'] || 50
    end

    def sauce_webdriver(sauce_config)
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

      Selenium::WebDriver.for :remote, :url => driver_url, :desired_capabilities => capabilities
    end

    def remote_webdriver(server_url)
      Selenium::WebDriver.for :remote, :url => server_url, :desired_capabilities => browser.to_sym
    end

    def local_webdriver
      selenium_options = {}
      if browser == 'firefox-firebug'
        require File.join(File.dirname(__FILE__), 'firebug/firebug')
        (profile = Selenium::WebDriver::Firefox::Profile.new)
        profile.enable_firebug
        selenium_options[:profile] = profile
      end
      Selenium::WebDriver.for(browser.to_sym, selenium_options)
    end

    protected
    attr_reader :formatter, :jasmine_server_url, :runner_config, :browser
  end
end

