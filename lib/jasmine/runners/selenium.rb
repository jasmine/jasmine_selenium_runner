require 'selenium-webdriver'

module Jasmine
  module Runners
    class Selenium
      def initialize(formatter, jasmine_server_url, config)
        @formatter = formatter
        @config = config
        @jasmine_server_url = jasmine_server_url
        browser = config.browser
        # @driver = if config.webdriver
                    # config.webdriver
                  # elsif selenium_server
                    # ::Selenium::WebDriver.for :remote, :url => selenium_server, :desired_capabilities => browser.to_sym
                  # else
                    # ::Selenium::WebDriver.for browser.to_sym, selenium_options(browser)
                  # end
        @driver = ::Selenium::WebDriver.for browser.to_sym, selenium_options(browser)
        @results = []
      end

      def run
        driver.navigate.to jasmine_server_url
        ensure_connection_established
        wait_for_suites_to_finish_running

        @results = get_results
        formatter.format(results)
        formatter.done
      ensure
        driver.quit
      end

      def succeeded?
        results.detect(&:failed?).nil?
      end

      private
      attr_reader :formatter, :config, :driver, :results, :jasmine_server_url

      def started?
        @driver.execute_script "return jsApiReporter && jsApiReporter.started"
      end

      def finished?
        @driver.execute_script "return jsApiReporter && jsApiReporter.finished"
      end

      def ensure_connection_established
        started = Time.now
        until started? do
          raise "couldn't connect to Jasmine after 60 seconds" if (started + 60 < Time.now)
          sleep 0.1
        end
      end

      def wait_for_suites_to_finish_running
        puts "Waiting for suite to finish in browser ..."
        until finished? do
          sleep 0.1
        end
      end

      def selenium_options(browser)
        # if browser == 'firefox-firebug'
          # require File.join(File.dirname(__FILE__), 'firebug/firebug')
          # (profile = Selenium::WebDriver::Firefox::Profile.new)
          # profile.enable_firebug
          # {:profile => profile}
        # else
          {}
        # end
      end

      def selenium_server
        # if config.selenium_server
          config.selenium_server
        # elsif config.selenium_server_port
          # "http://localhost:#{config.selenium_server_port}/wd/hub"
        # end
      end

      def get_results
        index = 0
        spec_results = []
        batch_size = config.result_batch_size

        loop do
          slice = get_results_slice(index, batch_size)
          spec_results << Jasmine::Result.map_raw_results(slice)
          index += batch_size

          break if slice.size < batch_size
        end

        spec_results.flatten
      end

      def get_results_slice(index, batch_size)
        driver.execute_script("return jsApiReporter.specResults(#{index}, #{batch_size})")
      end
    end
  end
end
