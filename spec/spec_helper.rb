require 'bundler/setup'
require 'panko'
require 'faker'

require_relative 'models'


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.full_backtrace = ENV.fetch('CI', false)

  config.before(:example, :focus) do
    fail 'This example was committed with `:focus` and should not have been'
  end if ENV.fetch('CI', false)

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    FooHolder.delete_all
    FoosHolder.delete_all
    Foo.delete_all
  end
end
