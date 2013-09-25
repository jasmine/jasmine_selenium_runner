require 'selenium-webdriver'

module Jasmine
  module Runners
    class Selenium
      def initialize(formatter, jasmine_server_url, driver, result_batch_size)
        @formatter = formatter
        @jasmine_server_url = jasmine_server_url
        @driver = driver
        @result_batch_size = result_batch_size
      end

      def run
        driver.navigate.to jasmine_server_url
        ensure_connection_established
        wait_for_suites_to_finish_running

        formatter.format(get_results)
        formatter.done
      ensure
        driver.quit
      end

      private
      attr_reader :formatter, :config, :driver, :jasmine_server_url, :result_batch_size

      def started?
        driver.execute_script "return jsApiReporter && jsApiReporter.started"
      end

      def finished?
        driver.execute_script "return jsApiReporter && jsApiReporter.finished"
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

      def get_results
        index = 0
        spec_results = []

        loop do
          slice = driver.execute_script("return jsApiReporter.specResults(#{index}, #{result_batch_size})")
          spec_results << Jasmine::Result.map_raw_results(slice)
          index += result_batch_size
          break if slice.size < result_batch_size
        end
        spec_results.flatten
      end

    end
  end
end
