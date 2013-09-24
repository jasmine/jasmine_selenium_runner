require 'rspec'
require 'jasmine_selenium_runner'

RSpec.configure do |config|
  config.before(:each, :sauce => true) do
    unless ENV["SAUCE_USERNAME"] && ENV["SAUCE_ACCESS_KEY"]
      pending "skipping sauce tests because SAUCE_USERNAME and SAUCE_ACCESS_KEY aren't set"
    end
  end
end
