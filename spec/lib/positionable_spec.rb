require 'spec_helper'

describe Positionable do

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
      @items = Array.new
      10.times { |n| @items << Factory.create(:item) }
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
      @middle.all_previous.size.should == @items.size - @middle.position
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
      @items[1..(@items.size - 1)].each do |item|
        item.first?.should be_false
      end
    end

    it "caracterizes the last record" do
      @items[0..(@items.size - 2)].each do |item|
        item.last?.should be_false
      end
      @items.last.last?.should be_true
    end

    it "decrements positions of next sibblings after deletion" do
      middle = @items.size / 2
      @middle.destroy
      @items[0..(middle - 1)].each_with_index do |item, index|
        item.reload.position.should == index
      end
      @items[(middle + 1)..(@items.size - 1)].each_with_index do |item, index|
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

    it "orders records by their position by default" do
      group = Factory.create(:group)
      shuffle_positions = (0..2).to_a.shuffle
      shuffle_positions.each do |position|
        sub_group = Factory.create(:sub_group, :group => group)
        sub_group.update_attribute(:position, position)
      end
      group.sub_groups.all.each_with_index do |sub_group, index|
        sub_group.position.should == index
      end
    end

  end

  after do
    SubGroup.delete_all
    Group.delete_all
    Item.delete_all
  end

end