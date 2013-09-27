require 'rspec'
require 'yaml'
require 'selenium-webdriver'
require 'jasmine_selenium_runner/configure_jasmine'

describe "Configuring jasmine" do

  class FakeConfig
    attr_accessor :port, :runner
  end

  def configure
    Dir.stub(:pwd).and_return(working_dir)
    Jasmine.stub(:configure).and_yield(fake_config)
    JasmineSeleniumRunner::ConfigureJasmine.install_selenium_runner
  end

  def stub_config_file(config_obj)
    config_path = File.join(working_dir, 'spec', 'javascripts', 'support', 'jasmine_selenium_runner.yml')
    File.stub(:exist?).with(config_path).and_return(true)
    File.stub(:read).with(config_path).and_return(YAML.dump(config_obj))
  end

  let(:working_dir) { 'hi' }
  let(:fake_config) { FakeConfig.new }

  context "when a custom selenium server is specified" do
    before do
      stub_config_file 'selenium_server' => 'http://example.com/selenium/stuff'
      configure
    end

    it "make a webdriver pointing to the custom server" do
      Selenium::WebDriver.should_receive(:for).with(:remote, hash_including(url: 'http://example.com/selenium/stuff'))
      fake_config.runner.call(nil, nil)
    end
  end
end
