require 'spec_helper'
require 'tmpdir'
require 'jasmine'

describe Jasmine::Runners::Selenium do
  let(:file_helper) { FileHelper.new }
  it "permits rake jasmine:ci task to be run using Selenium" do
    project_root = File.expand_path(File.join(__FILE__, '..', '..'))
    Dir.mktmpdir do |dir|
      begin
        Dir.chdir dir
        File.open(File.join(dir, 'Gemfile'), 'w') do |file|
          file.write <<-GEMFILE
source 'https://rubygems.org'
gem 'jasmine_selenium_runner', :path => '#{project_root}'
gem 'jasmine', :git => 'https://github.com/pivotal/jasmine-gem.git'
GEMFILE
        end
        Bundler.with_clean_env do
          `bundle`
          `bundle exec jasmine init`
          FileUtils.cp(File.join(project_root, 'spec', 'fixtures', 'is_in_firefox_spec.js'), File.join(dir, 'spec', 'javascripts'))
          ci_output = `bundle exec rake -E "require 'jasmine_selenium_runner'" --trace jasmine:ci`
          ci_output.should =~ (/[1-9][0-9]* specs, 0 failures/)
        end
      ensure
        Dir.chdir project_root
      end
    end
  end
end

