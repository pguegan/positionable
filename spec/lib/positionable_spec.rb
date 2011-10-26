require 'spec_helper'

describe Positionable do

  describe "extension" do

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

    it "protects the position attribute from mass assignment" do
      folder = Folder.new(:title => "A new folder", :position => 10)
      folder.position.should be_nil
      folder.save!
      folder.position.should == 0
      folder.update_attributes( {:position => 20} )
      folder.reload.position.should == 0
      folder = Folder.create(:title => "Another folder", :position => 30)
      folder.position.should == 1
    end

  end

  describe "scope" do

    it "orders records by their position by default" do
      shuffle_positions = (0..9).to_a.shuffle
      shuffle_positions.each do |position|
        folder = Folder.create(:title => "Folder at #{position}")
        folder.update_attribute(:position, position)
      end
      Folder.all.each_with_index do |folder, index|
        folder.position.should == index
      end
    end

  end

  describe "contiguous positionning" do

    before do
      @folders = Array.new
      10.times { |n| @folders << Folder.create(:title => "Folder #{n}") }
    end

    it "makes the position to start at zero" do
      @folders.first.position.should == 0
    end

    it "increments position by one after creation" do
      folder = Folder.create(:title => "Another folder")
      folder.position.should == @folders.last.position + 1
    end

    it "does not exist a previous for the first record" do
      @folders.first.previous.should be_nil
    end

    it "gives the previous record according to its position" do
      @folders[1..(@folders.size - 1)].each_with_index do |folder, index|
        folder.previous.should == @folders[index]
      end
    end

    it "gives all the previous records according to their positions" do
      middle = @folders.size / 2
      folder = @folders[middle]
      folder.all_previous.size.should == @folders.size - middle
      folder.all_previous.each_with_index do |previous, index|
        previous.should == @folders[index]
      end
    end

    it "does not exist a next for the last record" do
      @folders.last.next.should be_nil
    end

    it "gives the next record according to its position" do
      @folders[0..(@folders.size - 2)].each_with_index do |folder, index|
        folder.next.should == @folders[index + 1]
      end
    end

    it "gives all the next records according to their positions" do
      middle = @folders.size / 2
      folder = @folders[middle]
      folder.all_next.size.should == @folders.size - middle - 1
      folder.all_next.each_with_index do |neXt, index|
        neXt.should == @folders[middle + index + 1]
      end
    end

    it "caracterizes the first record" do
      @folders.first.first?.should be_true
      @folders[1..(@folders.size - 1)].each do |folder|
        folder.first?.should be_false
      end
    end

    it "caracterizes the last record" do
      @folders[0..(@folders.size - 2)].each do |folder|
        folder.last?.should be_false
      end
      @folders.last.last?.should be_true
    end

    it "decrements positions of next sibblings after deletion" do
      middle = @folders.size / 2
      @folders[middle].destroy
      @folders[0..(middle - 1)].each_with_index do |folder, index|
        folder.reload.position.should == index
      end
      @folders[(middle + 1)..(@folders.size - 1)].each_with_index do |folder, index|
        folder.reload.position.should == middle + index
      end
    end

  end

  after do
    Folder.delete_all
  end

end