require 'spec_helper'
require 'tmpdir'
require 'jasmine'
require 'json'
require 'net/http'
require 'bundler'

describe Jasmine::Runners::Selenium do
  let(:file_helper) { FileHelper.new }
  it "permits rake jasmine:ci task to be run using Selenium" do
    in_temp_dir do |dir, project_root|
      write_gemfile dir, project_root
      Bundler.with_clean_env do
        bundle_install
        `bundle exec jasmine init`
        `bundle exec jasmine examples`
        FileUtils.cp(File.join(project_root, 'spec', 'fixtures', 'is_in_firefox_spec.js'), File.join(dir, 'spec', 'javascripts'))
        ci_output = `bundle exec rake -E "require 'jasmine_selenium_runner'" --trace jasmine:ci`
        expect(ci_output).to match(/[1-9][0-9]* specs, 0 failures/)
      end
    end
  end

  it "allows rake jasmine:ci to retrieve results even though Selenium can't transmit back circular JS objects" do
    in_temp_dir do |dir, project_root|
      write_gemfile dir, project_root
      Bundler.with_clean_env do
        bundle_install
        `bundle exec jasmine init`
        `bundle exec jasmine examples`
        FileUtils.cp(File.join(project_root, 'spec', 'fixtures', 'contains_circular_references_spec.js'), File.join(dir, 'spec', 'javascripts'))
        ci_output = `bundle exec rake -E "require 'jasmine_selenium_runner'" --trace jasmine:ci`
        expect(ci_output).to match(/[1-9][0-9]* specs, 1 failure/)
      end
    end
  end

  it "reports failures in afterAll" do
    in_temp_dir do |dir, project_root|
      write_gemfile dir, project_root
      Bundler.with_clean_env do
        bundle_install
        `bundle exec jasmine init`
        `bundle exec jasmine examples`
        FileUtils.cp(File.join(project_root, 'spec', 'fixtures', 'after_all_failure_spec.js'), File.join(dir, 'spec', 'javascripts'))
        ci_output = `bundle exec rake -E "require 'jasmine_selenium_runner'" --trace jasmine:ci`
        expect(ci_output).to match(/afterAll go boom/)
        expect(ci_output).to match(/[1-9][0-9]* specs, 1 failure/)
      end
    end
  end

  it "reports random jasmine runs" do
    in_temp_dir do |dir, project_root|
      write_gemfile dir, project_root
      Bundler.with_clean_env do
        bundle_install
        `bundle exec jasmine init`
        `bundle exec jasmine examples`
        yaml_file = File.join(dir, 'spec', 'javascripts', 'support', 'jasmine.yml')
        jasmine_yaml = YAML.load_file(yaml_file)
        jasmine_yaml['random'] = true
        File.open(yaml_file, 'w') do |file|
          file.write(YAML.dump(jasmine_yaml))
          file.flush
        end
        ci_output = `bundle exec rake -E "require 'jasmine_selenium_runner'" --trace jasmine:ci`
        expect(ci_output).to match(/Randomized with seed/)
      end
    end
  end

  it "permits rake jasmine:ci task to be run using Sauce", :sauce => true do
    in_temp_dir do |dir, project_root|
      write_gemfile dir, project_root
      Bundler.with_clean_env do
        bundle_install
        `bundle exec jasmine init`
        `bundle exec jasmine examples`
        File.open(File.join(dir, 'spec', 'javascripts', 'support', 'jasmine_selenium_runner.yml'), 'w') do |file|
          file.write <<-YAML
---
use_sauce: true
browser: "internet explorer"
result_batch_size: 25
sauce:
  name: "jasmine_selenium_runner <%= Time.now.to_s %>"
  username: #{ENV['SAUCE_USERNAME']}
  access_key: #{ENV['SAUCE_ACCESS_KEY']}
  build: #{ENV['TRAVIS_BUILD_NUMBER'] || 'Ran locally'}
  tags:
    - #{ENV['TRAVIS_RUBY_VERSION'] || RUBY_VERSION}
    - CI
  tunnel_identifier: #{ENV['TRAVIS_JOB_NUMBER'] ? %Q("#{ENV['TRAVIS_JOB_NUMBER']}") : nil}
  sauce_connect_path: #{ENV['SAUCE_CONNECT_PATH']}
  os: "Windows 8"
  browser_version: 10
YAML
        end

        FileUtils.cp(File.join(project_root, 'spec', 'fixtures', 'is_in_ie_spec.js'), File.join(dir, 'spec', 'javascripts'))

        test_start_time = Time.now.to_i
        uri = URI.parse "https://saucelabs.com/rest/v1/#{ENV['SAUCE_USERNAME']}/jobs?from=#{test_start_time}"
        job_list_request = Net::HTTP::Get.new(uri)
        job_list_request.basic_auth(ENV['SAUCE_USERNAME'], ENV['SAUCE_ACCESS_KEY'])
        before = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(job_list_request)
        end
        expect(JSON.parse(before.body)).to be_empty
        ci_output = %x{bundle exec rake -E "require 'jasmine_selenium_runner'" --trace jasmine:ci}
        expect(ci_output).to match(/[1-9][0-9]* specs, 0 failures/)
        after = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(job_list_request)
        end
        expect(JSON.parse(after.body)).not_to be_empty
      end
    end
  end

  it "works with the rails asset pipeline" do
    in_temp_dir do |dir, project_root|
      `rails new rails-test --skip-spring --skip-bundle`
      Dir.chdir File.join(dir, 'rails-test')
      File.open('Gemfile', 'a') { |f|
        f.puts "gem 'jasmine', :git => 'https://github.com/jasmine/jasmine-gem.git'"
        f.puts "gem 'jasmine-core', :git => 'https://github.com/jasmine/jasmine.git'"
        f.puts "gem 'jasmine_selenium_runner', :path => '#{project_root}'"
      }

      Bundler.with_clean_env do
        bundle_install
        `bundle exec rails g jasmine:install`
        `bundle exec rails g jasmine:examples`
        FileUtils.cp(File.join(project_root, 'spec', 'fixtures', 'is_in_firefox_spec.js'), File.join(dir, 'rails-test', 'spec', 'javascripts'))
        output = `bundle exec rake jasmine:ci`
        expect(output).to match(/[1-9]\d* specs, 0 failures/)
      end
    end
  end

  def write_gemfile(dir, project_root)
    File.open(File.join(dir, 'Gemfile'), 'a') do |file|
      file.write <<-GEMFILE
source 'https://rubygems.org'
gem 'jasmine_selenium_runner', :path => '#{project_root}'
gem 'jasmine', :git => 'https://github.com/jasmine/jasmine-gem.git'
gem 'jasmine-core', :git => 'https://github.com/jasmine/jasmine.git'
      GEMFILE
    end
  end

  def bundle_install
    puts `NOKOGIRI_USE_SYSTEM_LIBRARIES=true bundle install --jobs=3 --retry=3 --path vendor;`
  end
end

