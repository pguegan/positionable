require 'spec_helper'

describe Positionable do

  before do
    Document.delete_all
    Folder.delete_all
    Item.delete_all
    Stuff.delete_all
    Dummy.delete_all
  end

  describe "extension" do

    it "extends positionable models" do
      item = Item.new
      item.respond_to?(:previous).should be_true
      item.respond_to?(:next).should be_true
    end

    it "does not extend non positionable models" do
      dummy = Dummy.new
      dummy.respond_to?(:previous).should be_false
      dummy.respond_to?(:next).should be_false
    end

    it "protects the position attribute from mass assignment" do
      item = Item.new(:title => "A new item", :position => 10)
      item.position.should be_nil
      item.save!
      item.position.should == 0
      item.update_attributes( {:position => 20} )
      item.reload.position.should == 0
      item = Item.create(:title => "Another item", :position => 30)
      item.position.should == 1
    end

  end

  describe "scope" do

    it "orders records by their position by default" do
      shuffle_positions = (0..9).to_a.shuffle
      shuffle_positions.each do |position|
        item = Factory.create(:item)
        item.update_attribute(:position, position)
      end
      Item.all.each_with_index do |item, index|
        item.position.should == index
      end
    end

  end

  describe "contiguous positionning" do

    before do
      @items = FactoryGirl.create_list(:item, 10)
      @middle = @items[@items.size / 2]
    end

    it "makes the position to start at zero" do
      @items.first.position.should == 0
    end

    it "increments position by one after creation" do
      item = Factory.create(:item)
      item.position.should == @items.last.position + 1
    end

    it "does not exist a previous for the first record" do
      @items.first.previous.should be_nil
    end

    it "gives the previous record according to its position" do
      @items[1..(@items.size - 1)].each_with_index do |item, index|
        item.previous.should == @items[index]
      end
    end

    it "gives all the previous records according to their positions" do
      @middle.all_previous.size.should == @middle.position
      @middle.all_previous.each_with_index do |previous, index|
        previous.should == @items[index]
      end
    end

    it "does not exist a next for the last record" do
      @items.last.next.should be_nil
    end

    it "gives the next record according to its position" do
      @items[0..(@items.size - 2)].each_with_index do |item, index|
        item.next.should == @items[index + 1]
      end
    end

    it "gives all the next records according to their positions" do
      @middle.all_next.size.should == @items.size - @middle.position - 1
      @middle.all_next.each_with_index do |neXt, index|
        neXt.should == @items[@middle.position + index + 1]
      end
    end

    it "caracterizes the first record" do
      @items.first.first?.should be_true
      @items.but_first.each do |item|
        item.first?.should be_false
      end
    end

    it "caracterizes the last record" do
      @items.but_last.each do |item|
        item.last?.should be_false
      end
      @items.last.last?.should be_true
    end

    it "decrements positions of next sibblings after deletion" do
      middle = @items.size / 2
      @middle.destroy
      @items.before(middle).each_with_index do |item, index|
        item.reload.position.should == index
      end
      @items.after(middle).each_with_index do |item, index|
        item.reload.position.should == middle + index
      end
    end

    it "does not up the first record" do
      item = @items.first
      item.position.should == 0
      item.up!
      item.position.should == 0
    end

    it "does not down the last record" do
      item = @items.last
      item.position.should == @items.size - 1
      item.down!
      item.position.should == @items.size - 1
    end

    it "reorders the records positions after upping" do
      position = @middle.position
      previous = @middle.previous
      neXt = @middle.next
      previous.position.should == position - 1
      neXt.position.should == position + 1
      @middle.up!
      previous.reload.position.should == position
      @middle.position.should == position - 1
      neXt.reload.position.should == position + 1
    end

    it "reorders the records positions after downing" do
      position = @middle.position
      previous = @middle.previous
      neXt = @middle.next
      previous.position.should == position - 1
      neXt.position.should == position + 1
      @middle.down!
      previous.reload.position.should == position - 1
      @middle.position.should == position + 1
      neXt.reload.position.should == position
    end

  end

  describe "grouping" do

    before do
      @folders = FactoryGirl.create_list(:folder_with_documents, 5)
    end

    it "orders records by their position by default" do
      @folders.each do |folder|
        documents = folder.documents
        shuffled_positions = (0..(documents.size - 1)).to_a.shuffle
        documents.each_with_index do |document, index|
          document.update_attribute(:position, shuffled_positions[index])
        end
        documents = folder.reload.documents
        documents.each_with_index do |document, index|
          document.position.should == index
        end
      end
    end

    it "makes the position to start at zero for each folder" do
      @folders.each do |folder|
        folder.documents.first.position.should == 0
      end
    end

    it "increments position by one after creation inside a folder" do
      folder = @folders.first
      last_position = folder.documents.last.position
      document = Factory.create(:document, :folder => folder)
      document.position.should == last_position + 1
    end

    it "does not exist a previous for the first record of each folder" do
      @folders.each do |folder|
        folder.documents.first.previous.should be_nil
      end
    end

    it "gives the previous record of the folder according to its position" do
      @folders.each do |folder|
        folder.documents.but_first.each_with_index do |document, index|
          document.previous.should == folder.documents[index]
        end
      end
    end

    it "gives all the previous records of the folder according to their positions" do
      @folders.each do |folder|
        documents = folder.documents
        middle = documents[documents.size / 2]
        middle.all_previous.size.should == middle.position
        middle.all_previous.each_with_index do |previous, index|
          previous.should == documents[index]
        end
      end
    end

    it "does not exist a next for the last record of the folder" do
      @folders.each do |folder|
        folder.documents.last.next.should be_nil
      end
    end

    it "gives the next record of the folder according to its position" do
      @folders.each do |folder|
        documents = folder.documents
        documents.but_last.each_with_index do |document, index|
          document.next.should == documents[index + 1]
        end
      end
    end

    it "gives all the next records of the folder according to their positions" do
      @folders.each do |folder|
        documents = folder.documents
        middle = documents[documents.size / 2]
        middle.all_next.size.should == documents.size - middle.position - 1
        middle.all_next.each_with_index do |neXt, index|
          neXt.should == documents[middle.position + index + 1]
        end
      end
    end

    it "caracterizes the first record of the folder" do
      @folders.each do |folder|
        documents = folder.documents
        documents.first.first?.should be_true
        documents.but_first.each do |document|
          document.first?.should be_false
        end
      end
    end

    it "caracterizes the last record of the folder" do
      @folders.each do |folder|
        documents = folder.documents
        documents.but_last.each do |document|
          document.last?.should be_false
        end
        documents.last.last?.should be_true
      end
    end

    it "decrements positions of next sibblings of the folder after deletion" do
      @folders.each do |folder|
        documents = folder.documents
        middle = documents.size / 2
        documents[middle].destroy
        documents.before(middle).each_with_index do |document, index|
          document.reload.position.should == index
        end
        documents.after(middle).each_with_index do |document, index|
          document.reload.position.should == middle + index
        end
      end
    end

    it "does not up the first record of the folder" do
      @folders.each do |folder|
        document = folder.documents.first
        document.position.should == 0
        document.up!
        document.position.should == 0
      end
    end

    it "does not down the last record of the folder" do
      @folders.each do |folder|
        document = folder.documents.last
        document.position.should == folder.documents.size - 1
        document.down!
        document.position.should == folder.documents.size - 1
      end
    end

    it "reorders the records positions after upping" do
      @folders.each do |folder|
        documents = folder.documents
        middle = documents[documents.size / 2]
        position = middle.position
        previous = middle.previous
        neXt = middle.next
        previous.position.should == position - 1
        neXt.position.should == position + 1
        middle.up!
        previous.reload.position.should == position
        middle.position.should == position - 1
        neXt.reload.position.should == position + 1
      end     
    end

    it "reorders the records positions after downing" do
      @folders.each do |folder|
        documents = folder.documents
        middle = documents[documents.size / 2]
        position = middle.position
        previous = middle.previous
        neXt = middle.next
        previous.position.should == position - 1
        neXt.position.should == position + 1
        middle.down!
        previous.reload.position.should == position - 1
        middle.position.should == position + 1
        neXt.reload.position.should == position
      end
    end

  end

  describe "start position" do

    let(:start) { 1 } # Check configuration of class Stuff in support/models.rb

    it "starts at zero by default" do
      item = Factory.create(:item)
      item.position.should == 0
    end

    it "starts at the given position" do
      stuff = Factory.create(:stuff)
      stuff.position.should == start
    end

    it "increments by one the given start position" do
      stuffs = FactoryGirl.create_list(:stuff, 5)
      stuff = Factory.create(:stuff)
      stuff.position.should == stuffs.size + start
    end

    it "caracterizes the first record according the start position" do
      stuffs = FactoryGirl.create_list(:stuff, 5)
      stuffs.first.first?.should be_true
      stuffs.but_first.each do |stuff|
        stuff.first?.should be_false
      end
    end

    it "caracterizes the last record according the start position" do
      stuffs = FactoryGirl.create_list(:stuff, 5)
      stuffs.but_last.each do |stuff|
        stuff.last?.should be_false
      end
      stuffs.last.last?.should be_true
    end

  end

end