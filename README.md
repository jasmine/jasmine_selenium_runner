# Jasmine Selenium Runner [![Build Status](https://travis-ci.org/jasmine/jasmine_selenium_runner.png?branch=master)](https://travis-ci.org/jasmine/jasmine_selenium_runner)

Runner for building Jasmine builds in Selenium (permitting automatic cross-browser testing).
After require-ing, jasmine_selenium_runner automatically sets itself up as the jasmine:ci runner.

## Installation

Add this line to your application's Gemfile (to test & dev groups):

    gem 'jasmine_selenium_runner'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jasmine_selenium_runner

### Basic Usage:

- In rails, simply `run rake jasmine:ci`, tests should run in firefox.
- Outside of rails, you may need to add `require 'jasmine_selenium_runner'` to your Rakefile after jasmine is required.

### Using w/ Travis (with xvfb): 

You'll want your .travis.yml file to look like the following:

    before_script:
    - sh -e /etc/init.d/xvfb start
    script: DISPLAY=:99.0 bundle exec rake jasmine:ci
    env:
      global:
      - JASMINE_BROWSER=firefox

### Using SauceLabs w/ Travis to run in multiple browsers:

Create a jasmine_selenium_runner.yml in spec/javascripts/support/ with the following content:

    ---
    use_sauce: <%= ENV['USE_SAUCE'] %>
    browser: <%= ENV['JASMINE_BROWSER'] %>
    sauce:
      name: some-project-name <%= Time.now.to_s %>
      username: <%= ENV['SAUCE_USERNAME'] %>
      access_key: <%= ENV['SAUCE_ACCESS_KEY'] %>
      build: <%= ENV['TRAVIS_BUILD_NUMBER'] || 'Ran locally' %>
      tags:
        - <%= ENV['TRAVIS_RUBY_VERSION'] || RUBY_VERSION %>
        - CI
      tunnel_identifier: <%= ENV['TRAVIS_JOB_NUMBER'] ? "#{ENV['TRAVIS_JOB_NUMBER']}" : nil %>
      os: <%= ENV['SAUCE_OS'] %>
      browser_version: <%= ENV['SAUCE_BROWSER_VERSION'] %>

Here's a compatible .travis.yml example (Travis has
[instructions for secure environment variables](http://about.travis-ci.org/docs/user/build-configuration/#Secure-environment-variables)
which you'll want for SAUCE_USERNAME and SAUCE_ACCESS_KEY):

    before_script:
    - curl https://gist.github.com/santiycr/5139565/raw/sauce_connect_setup.sh | bash
    script: bundle exec rake jasmine:ci
    rvm:
    - 2.0.0
    env:
      global:
      - USE_SAUCE=true
      - secure: some-secure-env-var
      - secure: some-other-secure-env-var
    matrix:
      include:
      - env:
        - JASMINE_BROWSER="firefox"
        - SAUCE_OS="Linux"
        - SAUCE_BROWSER_VERSION=''
      - env:
        - JASMINE_BROWSER="safari"
        - SAUCE_OS="OS X 10.8"
        - SAUCE_BROWSER_VERSION=6
      - env:
        - JASMINE_BROWSER="internet explorer"
        - SAUCE_OS="Windows 8"
        - SAUCE_BROWSER_VERSION=10
      - env:
      - env:
        - JASMINE_BROWSER="chrome"
        - SAUCE_OS="Linux"
        - SAUCE_BROWSER_VERSION=''

### Using with sauce connect locally

Sauce connect 4 now requires a path to the `sc` executable, so that needs to be provided if you want to use SauceLabs without a pre-existing tunnel.
In your jasmine_selenium_runner.yml, in the sauce section, you need to provide a `sauce_connect_path`.

    ---
    use_sauce: true
    sauce:
      sauce_connect_path: /my/path/to/sc

This configuration will only be used if no `tunnel_identifier` is provided.

### Using with a custom selenium server

Create a jasmine_selenium_runner.yml in spec/javascripts/support/ with the following content:

    ---
    selenium_server: <full url to selenium server>
    browser: <%= ENV['JASMINE_BROWSER'] %>

### Customizing the browser profile

Make a class that extends `JasmineSeleniumRunner::ConfigureJasmine` and override the `selenium_options` method

    class MyConfigurer < JasmineSeleniumRunner::ConfigureJasmine
      def selenium_options
        options = super
        if browser =~ /^firefox/
          options = super
          options[:profile] ||= Selenium::WebDriver::Firefox::Profile.new
          options[:profile]['dom.max_chrome_script_run_time'] = 20
          options[:profile]['dom.max_script_run_time'] = 20
        end
        options
      end
    end

Create a jasmine_selenium_runner.yml in spec/javascripts/support/ with the following content:

    ---
    configuration_class: MyConfigurer

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

