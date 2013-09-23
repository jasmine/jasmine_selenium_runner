require 'spec_helper'
require 'tmpdir'
require 'jasmine'

describe Jasmine::Runners::Selenium do
  let(:file_helper) { FileHelper.new }
  it "permits rake jasmine:ci task to be run using Selenium" do
    original_dir = Dir.pwd
    Dir.mktmpdir do |dir|
      begin
        Dir.chdir dir
        jasmine_gem_source = ENV["TRAVIS"] ? "github: 'pivotal/jasmine'" : ":path => '#{File.expand_path(File.join(original_dir, '..', 'jasmine-gem'))}'"
        File.open(File.join(dir, 'Gemfile'), 'w') do |file|
          file.write <<-GEMFILE
source 'https://rubygems.org'
gem 'jasmine_selenium_runner', :path => '#{original_dir}'
gem 'jasmine', #{jasmine_gem_source}
GEMFILE
        end
        Bundler.with_clean_env do
          `bundle`
          `bundle exec jasmine init`
          ci_output = `bundle exec rake -E "require 'jasmine_selenium_runner'" --trace jasmine:ci`
          ci_output.should =~ (/[1-9][0-9]* specs, 0 failures/)
          ci_output.should =~ (/Run with Selenium/)
        end
      ensure
        Dir.chdir original_dir
      end
    end
  end
end

