require 'spec_helper'

describe Positionable do

  before do
    SubGroup.delete_all
    Group.delete_all
    Item.delete_all
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
      @groups = FactoryGirl.create_list(:group_with_sub_groups, 5)
    end

    it "orders records by their position by default" do
      @groups.each do |group|
        sub_groups = group.sub_groups
        shuffled_positions = (0..(sub_groups.size - 1)).to_a.shuffle
        sub_groups.each_with_index do |sub_group, index|
          sub_group.update_attribute(:position, shuffled_positions[index])
        end
        sub_groups = group.reload.sub_groups
        sub_groups.each_with_index do |sub_group, index|
          sub_group.position.should == index
        end
      end
    end

    it "makes the position to start at zero for each group" do
      @groups.each do |group|
        group.sub_groups.first.position.should == 0
      end
    end

    it "increments position by one after creation inside a group" do
      group = @groups.first
      last_position = group.sub_groups.last.position
      sub_group = Factory.create(:sub_group, :group => group)
      sub_group.position.should == last_position + 1
    end

    it "does not exist a previous for the first record of each group" do
      @groups.each do |group|
        group.sub_groups.first.previous.should be_nil
      end
    end

    it "gives the previous record of the group according to its position" do
      @groups.each do |group|
        group.sub_groups.but_first.each_with_index do |sub_group, index|
          sub_group.previous.should == group.sub_groups[index]
        end
      end
    end

    it "gives all the previous records of the group according to their positions" do
      @groups.each do |group|
        sub_groups = group.sub_groups
        middle = sub_groups[sub_groups.size / 2]
        middle.all_previous.size.should == middle.position
        middle.all_previous.each_with_index do |previous, index|
          previous.should == sub_groups[index]
        end
      end
    end

    it "does not exist a next for the last record of the group" do
      @groups.each do |group|
        group.sub_groups.last.next.should be_nil
      end
    end

    it "gives the next record of the group according to its position" do
      @groups.each do |group|
        sub_groups = group.sub_groups
        sub_groups.but_last.each_with_index do |sub_group, index|
          sub_group.next.should == sub_groups[index + 1]
        end
      end
    end

    it "gives all the next records of the group according to their positions" do
      @groups.each do |group|
        sub_groups = group.sub_groups
        middle = sub_groups[sub_groups.size / 2]
        middle.all_next.size.should == sub_groups.size - middle.position - 1
        middle.all_next.each_with_index do |neXt, index|
          neXt.should == sub_groups[middle.position + index + 1]
        end
      end
    end

    it "caracterizes the first record of the group" do
      @groups.each do |group|
        sub_groups = group.sub_groups
        sub_groups.first.first?.should be_true
        sub_groups.but_first.each do |sub_group|
          sub_group.first?.should be_false
        end
      end
    end

    it "caracterizes the last record of the group" do
      @groups.each do |group|
        sub_groups = group.sub_groups
        sub_groups.but_last.each do |sub_group|
          sub_group.last?.should be_false
        end
        sub_groups.last.last?.should be_true
      end
    end

    it "decrements positions of next sibblings of the group after deletion" do
      @groups.each do |group|
        sub_groups = group.sub_groups
        middle = sub_groups.size / 2
        sub_groups[middle].destroy
        sub_groups.before(middle).each_with_index do |sub_group, index|
          sub_group.reload.position.should == index
        end
        sub_groups.after(middle).each_with_index do |sub_group, index|
          sub_group.reload.position.should == middle + index
        end
      end
    end

    it "does not up the first record of the group" do
      @groups.each do |group|
        sub_group = group.sub_groups.first
        sub_group.position.should == 0
        sub_group.up!
        sub_group.position.should == 0
      end
    end

    it "does not down the last record of the group" do
      @groups.each do |group|
        sub_group = group.sub_groups.last
        sub_group.position.should == group.sub_groups.size - 1
        sub_group.down!
        sub_group.position.should == group.sub_groups.size - 1
      end
    end

    it "reorders the records positions after upping" do
      @groups.each do |group|
        sub_groups = group.sub_groups
        middle = sub_groups[sub_groups.size / 2]
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
      @groups.each do |group|
        sub_groups = group.sub_groups
        middle = sub_groups[sub_groups.size / 2]
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

end