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
        formatter.done(run_details)
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

      def run_details
        driver.execute_script "return jsApiReporter && jsApiReporter.runDetails"
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
        failed_suite_results = []

        loop do
          slice = results_without_circular_references('spec', index)
          spec_results << slice
          index += result_batch_size
          break if slice.size < result_batch_size
        end

        index = 0
        loop do
          slice = results_without_circular_references('suite', index)
          failed_suite_results << slice.select(&:failed?)
          index += result_batch_size
          break if slice.size < result_batch_size
        end

        spec_results.flatten + failed_suite_results.flatten
      end

      def results_without_circular_references(result_type, starting_index)
        slice = driver.execute_script(<<-JS)
          var results = jsApiReporter.#{result_type}Results(#{starting_index}, #{result_batch_size})
          for (var i = 0; i < results.length; i++) {
            var expectations = results[i].failedExpectations;
            if (results[i].passedExpectations) {
              expectations = expectations.concat(results[i].passedExpectations);
            }
            for (var j = 0; j < expectations.length; j++) {
              var expectation = expectations[j];
              try { JSON.stringify(expectation.expected); } catch (e) { expectation.expected = '<circular expected>'; }
              try { JSON.stringify(expectation.actual); } catch (e) { expectation.actual = '<circular actual>'; }
            }
          }
          return results;
        JS
        Jasmine::Result.map_raw_results(slice)
      end
    end
  end
end
