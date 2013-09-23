source 'https://rubygems.org'

gemspec

if ENV['TRAVIS']
  gem 'jasmine', :git => 'http://github.com/pivotal/jasmine-gem.git'
else
  gem 'jasmine', :path => '../jasmine-gem'
end

