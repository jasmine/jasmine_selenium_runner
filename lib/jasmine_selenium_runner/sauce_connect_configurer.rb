module JasmineSeleniumRunner
  module SauceConnectConfigurer
    def self.configure
      require 'sauce'
      require 'sauce/connect'
      Sauce.config do |config|
        yield config
      end
      Sauce::Connect.connect!
    end
  end
end
