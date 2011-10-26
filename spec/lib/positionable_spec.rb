require 'spec_helper'

describe Positionable do

  it "makes position start at zero" do
    folder = Folder.create(:title => "A new folder")
    folder.position.should == 0
  end

  it "extends positionable models" do
    folder = Folder.new
    folder.respond_to?(:previous).should be_true
    folder.respond_to?(:next).should be_true
  end

  it "does not extend non positionable models" do
    dummy = Dummy.new
    dummy.respond_to?(:previous).should be_false
    dummy.respond_to?(:next).should be_false
  end

end