require 'rspec'
require 'jasmine_selenium_runner'

RSpec.configure do |config|
  config.before(:each, :sauce => true) do
    unless ENV["SAUCE_USERNAME"] && ENV["SAUCE_ACCESS_KEY"]
      skip "skipping sauce tests because SAUCE_USERNAME and SAUCE_ACCESS_KEY aren't set"
    end
  end
end

def in_temp_dir
  project_root = File.expand_path(File.join('..', '..'), __FILE__)
  Dir.mktmpdir do |tmp_dir|
    begin
      Dir.chdir tmp_dir
      yield tmp_dir, project_root
    ensure
      Dir.chdir project_root
    end
  end
end
