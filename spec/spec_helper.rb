require 'simplecov'
SimpleCov.start

require 'factory_girl'
FactoryGirl.find_definitions

require 'positionable'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => File.dirname(__FILE__) + "/positionable.sqlite3")

load File.dirname(__FILE__) + '/support/schema.rb'
load File.dirname(__FILE__) + '/support/models.rb'