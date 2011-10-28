require 'simplecov'
SimpleCov.start

require 'factory_girl'
FactoryGirl.find_definitions

require 'positionable'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => File.dirname(__FILE__) + "/positionable.sqlite3")

load File.dirname(__FILE__) + '/support/schema.rb'
load File.dirname(__FILE__) + '/support/models.rb'

class Array

  def but_last
    self[0..(size - 2)]
  end

  def but_first
    self[1..(size - 1)]
  end

  def before(index)
    self[0..(index - 1)] if index > 0 and index < size
  end

  def after(index)
    self[(index + 1)..(size - 1)] if index > 0 and index < size
  end

end