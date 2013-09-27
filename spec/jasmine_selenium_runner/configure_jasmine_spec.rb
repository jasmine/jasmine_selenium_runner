require 'rspec'
require 'yaml'
require 'selenium-webdriver'
require 'jasmine_selenium_runner/configure_jasmine'

describe "Configuring jasmine" do
  let(:configurer) { JasmineSeleniumRunner::ConfigureJasmine.new(nil, nil, config) }

  context "when a custom selenium server is specified" do
    let(:config) { { 'selenium_server' => 'http://example.com/selenium/stuff' }}

    it "make a webdriver pointing to the custom server" do
      Selenium::WebDriver.should_receive(:for).with(:remote, hash_including(url: 'http://example.com/selenium/stuff'))
      configurer.make_runner
    end
  end

  context "when the user wants firebug installed" do
    let(:config) { { 'browser' => 'firefox-firebug' } }

    it "should create a firebug profile and pass that to WebDriver" do
      profile = double(:profile, enable_firebug: nil)
      Selenium::WebDriver::Firefox::Profile.stub(:new).and_return(profile)
      Selenium::WebDriver.should_receive(:for).with('firefox-firebug'.to_sym, {profile: profile})
      configurer.make_runner
    end
  end
end
