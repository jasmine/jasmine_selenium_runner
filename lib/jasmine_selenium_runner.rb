def safe_gem_check(gem_name, version_string)
  if Gem::Specification.respond_to?(:find_by_name)
    Gem::Specification.find_by_name(gem_name, version_string)
  elsif Gem.respond_to?(:available?)
    Gem.available?(gem_name, version_string)
  end
rescue Gem::LoadError
  false
end

if safe_gem_check('rails', '>= 3')
  require File.join('jasmine_selenium_runner', 'railtie')
else
  require File.join('jasmine_selenium_runner', 'configure_jasmine.rb')
  JasmineSeleniumRunner::ConfigureJasmine.install_selenium_runner
end
