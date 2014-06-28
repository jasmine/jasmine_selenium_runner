require 'rspec'
require 'yaml'
require 'selenium-webdriver'
require 'jasmine_selenium_runner/configure_jasmine'

describe "Configuring jasmine" do
  let(:configurer) { JasmineSeleniumRunner::ConfigureJasmine.new(nil, nil, config) }

  context "when a custom selenium server is specified" do
    let(:config) { { 'selenium_server' => 'http://example.com/selenium/stuff' }}

    it "make a webdriver pointing to the custom server" do
      expect(Selenium::WebDriver).to receive(:for).with(:remote, hash_including(url: 'http://example.com/selenium/stuff'))
      configurer.make_runner
    end
  end

  context "when the user wants firebug installed" do
    let(:config) { { 'browser' => 'firefox-firebug' } }

    it "should create a firebug profile and pass that to WebDriver" do
      profile = double(:profile, enable_firebug: nil)
      allow(Selenium::WebDriver::Firefox::Profile).to receive(:new).and_return(profile)
      expect(Selenium::WebDriver).to receive(:for).with('firefox-firebug'.to_sym, {profile: profile})
      configurer.make_runner
    end
  end

  context "specifying a custom configurer" do
    class FakeConfig
      attr_accessor :port, :runner
    end

    def configure
      allow(Dir).to receive(:pwd).and_return(working_dir)
      allow(Jasmine).to receive(:configure).and_yield(fake_config)
      JasmineSeleniumRunner::ConfigureJasmine.install_selenium_runner
    end

    def stub_config_file(config_obj)
      config_path = File.join(working_dir, 'spec', 'javascripts', 'support', 'jasmine_selenium_runner.yml')
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(config_path).and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(config_path).and_return(YAML.dump(config_obj))
    end

    let(:working_dir) { 'hi' }
    let(:fake_config) { FakeConfig.new }

    module Foo
      class Bar
        def initialize(formatter, jasmine_server_url, config)
        end

        def make_runner
        end
      end
    end

    before do
      stub_config_file 'configuration_class' => 'Foo::Bar'
      configure
    end

    it "should use the custom class" do
      expect(Selenium::WebDriver).not_to receive(:for)
      expect_any_instance_of(Foo::Bar).to receive(:make_runner)
      fake_config.runner.call(nil, nil)
    end
  end
end
