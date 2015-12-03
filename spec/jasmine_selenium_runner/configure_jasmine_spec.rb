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

    def stub_config_file(config_obj, config_path=nil)
      config_path ||= File.join(working_dir, 'spec', 'javascripts', 'support', 'jasmine_selenium_runner.yml')
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

    context 'with the default config file location' do
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

    context 'with a custom config file path' do
      before do
        stub_config_file({ 'configuration_class' => 'Foo::Bar' }, '/tmp/config.yml')
        ENV['JASMINE_SELENIUM_CONFIG_PATH'] = '/tmp/config.yml'
        configure
      end

      after do
        ENV.delete 'JASMINE_SELENIUM_CONFIG_PATH'
      end

      it "should use the custom class" do
        expect(Selenium::WebDriver).not_to receive(:for)
        expect_any_instance_of(Foo::Bar).to receive(:make_runner)
        fake_config.runner.call(nil, nil)
      end
    end
  end

  context 'configuring sauce labs' do
    before do
      allow(Selenium::WebDriver).to receive(:for) { mock_driver }
      allow(Jasmine::Runners::Selenium).to receive(:new)
      allow(JasmineSeleniumRunner::SauceConnectConfigurer).to receive(:configure).and_yield(sauce_config)
    end

    let(:sauce_thing) { double(:sauce_thing) }
    let(:mock_driver) { double(:mock_driver) }
    let(:sauce_config) { double(:sauce_config, :[]= => nil) }

    context 'with an existing tunnel' do
      it 'uses the tunnel identifier' do
        runner = JasmineSeleniumRunner::ConfigureJasmine.new(double(:formatter), 'jasmine_url', {
          'use_sauce' => true,
          'sauce' => {
            'username' => 'sauce_user',
            'access_key' => 'sauce_key',
            'name' => 'sauce_name',
            'os' => 'sauce_os',
            'browser_version' => 'browser_version',
            'build' => 'build',
            'tags' => 'tags',
            'tunnel_identifier' => 'tunnel'
          }
        }) do |thing|

        end

        runner.make_runner

        expect(JasmineSeleniumRunner::SauceConnectConfigurer).not_to have_received(:configure)
        expect(Selenium::WebDriver).to have_received(:for).with(:remote,
                                                                :url => 'http://sauce_user:sauce_key@localhost:4445/wd/hub',
                                                                :desired_capabilities => {
                                                                  :name => 'sauce_name',
                                                                  :platform => 'sauce_os',
                                                                  :version => 'browser_version',
                                                                  :build => 'build',
                                                                  :tags => 'tags',
                                                                  :browserName => 'firefox',
                                                                  'tunnel-identifier' => 'tunnel'
                                                                }
                                                               )
      end
    end

    context 'without an existing tunnel' do
      it 'uses sauce connect' do
        runner = JasmineSeleniumRunner::ConfigureJasmine.new(double(:formatter), 'jasmine_url', {
          'use_sauce' => true,
          'sauce' => {
            'username' => 'sauce_user',
            'access_key' => 'sauce_key',
            'name' => 'sauce_name',
            'os' => 'sauce_os',
            'browser_version' => 'browser_version',
            'build' => 'build',
            'tags' => 'tags',
            'sauce_connect_path' => '/path/to/sc'
          }
        })


        runner.make_runner

        expect(JasmineSeleniumRunner::SauceConnectConfigurer).to have_received(:configure)
        expect(sauce_config).to have_received(:[]=).with(:sauce_connect_4_executable, '/path/to/sc')
        expect(Selenium::WebDriver).to have_received(:for).with(:remote,
                                                                :url => 'http://sauce_user:sauce_key@localhost:4445/wd/hub',
                                                                :desired_capabilities => {
                                                                  :name => 'sauce_name',
                                                                  :platform => 'sauce_os',
                                                                  :version => 'browser_version',
                                                                  :build => 'build',
                                                                  :tags => 'tags',
                                                                  :browserName => 'firefox',
                                                                  'tunnel-identifier' => nil
                                                                }
                                                               )
      end
    end
  end
end
