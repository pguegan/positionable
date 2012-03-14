require 'spec_helper'

describe Positionable do

  before do
    Document.delete_all
    Folder.delete_all
    Item.delete_all
    Dummy.delete_all
  end

  context "ActiveRecord extension" do

    it "does not extend non positionable models" do
      dummy = Dummy.new
      dummy.respond_to?(:previous).should be_false
      dummy.respond_to?(:next).should be_false
      dummy.respond_to?(:position=).should be_false
    end

    it "extends positionable models" do
      item = DefaultItem.new
      item.respond_to?(:previous).should be_true
      item.respond_to?(:next).should be_true
      item.respond_to?(:position=).should be_true
    end

    it "prepends the table name in SQL 'order by' clause" do
      sql = DefaultItem.where("1 = 1").to_sql
      table = DefaultItem.table_name
      sql.should include("ORDER BY \"#{table}\".\"position\"")
    end

    context "inheritance" do

      it "extends positionable sub-models" do
        item = SubItem1.new
        item.respond_to?(:previous).should be_true
        item.respond_to?(:next).should be_true
        item.respond_to?(:position=).should be_true
      end

    end

  end

  context "ordering" do

    it "orders records by their position by default" do
      shuffle_positions = (0..9).to_a.shuffle
      shuffle_positions.each do |position|
        item = Factory.create(:default_item)
        item.update_column(:position, position)
      end
      DefaultItem.all.should be_contiguous.starting_at(0)
    end

  end

  context "contiguous positionning" do

    let!(:items) { FactoryGirl.create_list(:default_item, 10) }
    let(:middle) { items[items.size / 2] }

    it "makes the position to start at zero by default" do
      items.first.position.should == 0
    end

    it "increments position by one after creation" do
      item = Factory.create(:default_item)
      item.position.should == items.last.position + 1
    end

    it "does not exist a previous for the first record" do
      items.first.previous.should be_nil
    end

    it "gives the previous record according to its position" do
      items[1..(items.size - 1)].each_with_index do |item, index|
        item.previous.should == items[index]
      end
    end

    it "gives all the previous records according to their positions" do
      middle.all_previous.size.should == middle.position
      middle.all_previous.each_with_index do |previous, index|
        previous.should == items[index]
      end
    end

    it "does not exist a next for the last record" do
      items.last.next.should be_nil
    end

    it "gives the next record according to its position" do
      items[0..(items.size - 2)].each_with_index do |item, index|
        item.next.should == items[index + 1]
      end
    end

    it "gives all the next records according to their positions" do
      middle.all_next.size.should == items.size - middle.position - 1
      middle.all_next.each_with_index do |neXt, index|
        neXt.should == items[middle.position + index + 1]
      end
    end

    it "caracterizes the first record" do
      items.first.first?.should be_true
      items.but_first.each do |item|
        item.first?.should be_false
      end
    end

    it "caracterizes the last record" do
      items.but_last.each do |item|
        item.last?.should be_false
      end
      items.last.last?.should be_true
    end

    it "decrements positions of next sibblings after deletion" do
      position = items.size / 2
      middle.destroy
      items.before(position).should be_contiguous.starting_at(0)
      items.after(position).should be_contiguous.starting_at(position)
    end

    it "does not up the first record" do
      item = items.first
      item.position.should == 0 # Meta!
      item.up!
      item.position.should == 0
    end

    it "does not down the last record" do
      item = items.last
      item.position.should == items.size - 1 # Meta!
      item.down!
      item.position.should == items.size - 1
    end

    it "reorders the records positions after upping" do
      position = middle.position
      previous = middle.previous
      neXt = middle.next
      previous.position.should == position - 1 # Meta!
      neXt.position.should == position + 1 # Meta!
      middle.up!
      previous.reload.position.should == position
      middle.position.should == position - 1
      neXt.reload.position.should == position + 1
    end

    it "reorders the records positions after downing" do
      position = middle.position
      previous = middle.previous
      neXt = middle.next
      previous.position.should == position - 1 # Meta!
      neXt.position.should == position + 1 # Meta!
      middle.down!
      previous.reload.position.should == position - 1
      middle.position.should == position + 1
      neXt.reload.position.should == position
    end

    context "inheritance" do

      it "inserts contiguously records of all subclasses" do
        Factory.create(:sub_item_1).position.should == items.count
        Factory.create(:sub_item_2).position.should == items.count + 1
        Factory.create(:sub_item_1).position.should == items.count + 2
      end

    end

    describe "moving" do

      context "mass-assignement" do
        
        it "reorders records when position is updated" do
          old_position = middle.position
          new_position = old_position + 3
          middle.update_attributes({ :position => new_position })
          (0..(old_position - 1)).each do |position|
            items[position].reload.position.should == position
          end
          middle.position.should == new_position
          ((old_position + 1)..new_position).each do |position|
            items[position].reload.position.should == position - 1
          end
          ((new_position + 1)..(items.count - 1)).each do |position|
            items[position].reload.position.should == position
          end
        end

        it "does not reorder anything when position is updated but out of range" do
          middle.update_attributes({ :position => items.count + 10 })
          items.should be_contiguous.starting_at(0)
        end

        it "does not reorder anything when position is updated but before start" do
          middle.update_attributes({ :position => -1 })
          items.should be_contiguous.starting_at(0)
        end
      
      end

      it "also moves the previous records when moving to a lower position" do
        old_position = middle.position
        new_position = old_position - 3
        middle.move_to new_position
        (0..(new_position - 1)).each do |position|
          items[position].reload.position.should == position
        end
        middle.position.should == new_position
        (new_position..(old_position - 1)).each do |position|
          items[position].reload.position.should == position + 1
        end
        ((old_position + 1)..(items.count - 1)).each do |position|
          items[position].reload.position.should == position
        end
      end

      it "also moves the next records when moving to a higher position" do
        old_position = middle.position
        new_position = old_position + 3
        middle.move_to new_position
        (0..(old_position - 1)).each do |position|
          items[position].reload.position.should == position
        end
        middle.position.should == new_position
        ((old_position + 1)..new_position).each do |position|
          items[position].reload.position.should == position - 1
        end
        ((new_position + 1)..(items.count - 1)).each do |position|
          items[position].reload.position.should == position
        end
      end

      it "does not move anything if new position is before start position" do
        lambda {
          middle.move_to -1
        }.should_not change(middle, :position)
      end

      it "does not move anything if new position is out of range" do
        lambda {
          middle.move_to items.count + 10
        }.should_not change(middle, :position)
      end

    end

  end

  describe "range" do

    let!(:items) { FactoryGirl.create_list(:default_item, 10) }

    it "gives the range position of a new record" do
      item = Factory.build(:default_item)
      item.range.should == (0..items.count)
    end

    it "gives the range position of an existing record" do
      items.sample.range.should == (0..(items.count - 1))
    end

  end

  context "scoping" do

    let!(:folders) { FactoryGirl.create_list(:folder_with_documents, 5) }

    it "orders records by their position by default" do
      folders.each do |folder|
        documents = folder.documents
        shuffled_positions = (0..(documents.size - 1)).to_a.shuffle
        documents.each_with_index do |document, index|
          document.update_column(:position, shuffled_positions[index])
        end
        documents = folder.reload.documents
        documents.should be_contiguous.starting_at(0)
      end
    end

    it "makes the position to start at zero for each folder" do
      folders.each do |folder|
        folder.documents.first.position.should == 0
      end
    end

    it "increments position by one after creation inside a folder" do
      folders.each do |folder|
        last_position = folder.documents.last.position
        document = Factory.create(:document, :folder => folder)
        document.position.should == last_position + 1
      end
    end

    it "does not exist a previous for the first record of each folder" do
      folders.each do |folder|
        folder.documents.first.previous.should be_nil
      end
    end

    it "gives the previous record of the folder according to its position" do
      folders.each do |folder|
        folder.documents.but_first.each_with_index do |document, index|
          document.previous.should == folder.documents[index]
        end
      end
    end

    it "gives all the previous records of the folder according to their positions" do
      folders.each do |folder|
        documents = folder.documents
        middle = documents[documents.size / 2]
        middle.all_previous.size.should == middle.position
        middle.all_previous.each_with_index do |previous, index|
          previous.should == documents[index]
        end
      end
    end

    it "does not exist a next for the last record of the folder" do
      folders.each do |folder|
        folder.documents.last.next.should be_nil
      end
    end

    it "gives the next record of the folder according to its position" do
      folders.each do |folder|
        documents = folder.documents
        documents.but_last.each_with_index do |document, index|
          document.next.should == documents[index + 1]
        end
      end
    end

    it "gives all the next records of the folder according to their positions" do
      folders.each do |folder|
        documents = folder.documents
        middle = documents[documents.size / 2]
        middle.all_next.count.should == documents.count - middle.position - 1
        middle.all_next.each_with_index do |neXt, index|
          neXt.should == documents[middle.position + index + 1]
        end
      end
    end

    it "caracterizes the first record of the folder" do
      folders.each do |folder|
        documents = folder.documents
        documents.first.first?.should be_true
        documents.but_first.each do |document|
          document.first?.should be_false
        end
      end
    end

    it "caracterizes the last record of the folder" do
      folders.each do |folder|
        documents = folder.documents
        documents.but_last.each do |document|
          document.last?.should be_false
        end
        documents.last.last?.should be_true
      end
    end

    it "decrements positions of next sibblings of the folder after deletion" do
      folders.each do |folder|
        documents = folder.documents
        middle = documents.size / 2
        documents[middle].destroy
        documents.before(middle).should be_contiguous.starting_at(0)
        documents.after(middle).should be_contiguous.starting_at(middle)
      end
    end

    it "does not up the first record of the folder" do
      folders.each do |folder|
        document = folder.documents.first
        document.position.should == 0 # Meta!
        lambda {
          document.up!
        }.should_not change(document, :position)
      end
    end

    it "does not down the last record of the folder" do
      folders.each do |folder|
        document = folder.documents.last
        document.position.should == folder.documents.size - 1 # Meta!
        lambda {
          document.down!
        }.should_not change(document, :position)
      end
    end

    it "reorders the records positions after upping" do
      folders.each do |folder|
        documents = folder.documents
        middle = documents[documents.size / 2]
        position = middle.position
        previous = middle.previous
        neXt = middle.next
        previous.position.should == position - 1 # Meta!
        neXt.position.should == position + 1 # Meta!
        middle.up!
        previous.reload.position.should == position
        middle.position.should == position - 1
        neXt.reload.position.should == position + 1
      end     
    end

    it "reorders the records positions after downing" do
      folders.each do |folder|
        documents = folder.documents
        middle = documents[documents.size / 2]
        position = middle.position
        previous = middle.previous
        neXt = middle.next
        previous.position.should == position - 1 # Meta!
        neXt.position.should == position + 1 # Meta!
        middle.down!
        previous.reload.position.should == position - 1
        middle.position.should == position + 1
        neXt.reload.position.should == position
      end
    end

    context "changing scope" do

      let!(:old_folder) { folders.first }
      # Last document is a special case when changing scope, so it is avoided
      let!(:document) { old_folder.documents.but_last.sample }
      # A new folder containing a different count of documents than the old folder
      let!(:new_folder) { Factory.create(:folder) }
      let!(:new_documents) { FactoryGirl.create_list(:document, old_folder.documents.count + 1, :folder => new_folder) }

      it "moves to bottom position when scope has changed but position is out of range" do
        document.update_attributes( {:folder_id => new_folder.id, :position => new_documents.count + 10 } )
        document.position.should == new_folder.documents.count - 1
        document.last?.should be_true
      end

      it "keeps position when scope has changed but position belongs to range" do
        position = document.position
        document.update_attributes( {:folder_id => new_folder.id} )
        document.position.should == position # Position unchanged
        new_folder.reload.documents.should be_contiguous.starting_at(0)
      end

      it "reorders records of previous scope" do
        document.update_attributes( {:folder_id => new_folder.id} )
        old_folder.reload.documents.should be_contiguous.starting_at(0)
      end

    end

    describe "range" do

      context "new record" do

        it "gives a range only if the scope is specified" do
          lambda {
            Document.new.range
          }.should raise_error(Positionable::RangeWithoutScopeError)
        end

        it "gives the range within a scope" do
          folder = Factory.create(:folder_with_documents)
          document = Document.new
          document.range(folder).should == (0..folder.documents.count)
        end

        it "gives the range within its own scope by default" do
          folder = Factory.create(:folder_with_documents)
          document = folder.documents.sample
          document.range.should == (0..(folder.documents.count - 1))
        end

        it "gives the range within another scope" do
          document = Factory.build(:document)
          folder = Factory.create(:folder_with_documents)
          document.folder.should_not == folder # Meta!
          document.range(folder).should == (0..folder.documents.count)
        end

        it "gives the range within another empty scope" do
          document = Factory.build(:document)
          folder = Factory.create(:folder)
          document.folder.should_not == folder # Meta!
          folder.documents.should be_empty # Meta!
          document.range(folder).should == (0..0)
        end

      end

      context "existing record" do

        it "gives the range within its own scope" do
          folder = Factory.create(:folder_with_documents)
          document = folder.documents.sample
          document.range(folder).should == (0..(folder.documents.count - 1))
        end

        it "gives the range within another scope" do
          document = Factory.create(:document)
          folder = Factory.create(:folder_with_documents)
          document.folder.should_not == folder # Meta!
          document.range(folder).should == (0..folder.documents.count)
        end

      end

    end

  end

  context "start position" do

    let(:start) { 1 }

    it "starts at the given position" do
      item = Factory.create(:starting_at_one_item)
      item.position.should == start
    end

    it "increments by one the given start position" do
      items = FactoryGirl.create_list(:starting_at_one_item, 5)
      item = Factory.create(:starting_at_one_item)
      item.position.should == items.size + start
    end

    it "caracterizes the first record according the start position" do
      items = FactoryGirl.create_list(:starting_at_one_item, 5)
      items.first.first?.should be_true
      items.but_first.each do |item|
        item.first?.should be_false
      end
    end

    it "caracterizes the last record according the start position" do
      items = FactoryGirl.create_list(:starting_at_one_item, 5)
      items.but_last.each do |item|
        item.last?.should be_false
      end
      items.last.last?.should be_true
    end

    describe "moving" do

      it "does not move anything if new position is before start position" do
        items = FactoryGirl.create_list(:starting_at_one_item, 5)
        item = items.sample
        lambda {
          item.move_to start - 1
        }.should_not change(item, :position)
      end

    end

    describe "range" do

      it "staggers range with start position" do
        items = FactoryGirl.create_list(:starting_at_one_item, 5)
        items.sample.range.should == (start..(items.count + start - 1))
      end

    end

  end

  context "insertion order" do

    describe "asc" do

      it "appends at the last position" do
        items = FactoryGirl.create_list(:asc_item, 5)
        item = Factory.create(:asc_item)
        item.position.should == items.size
      end

      it "orders items by ascending position" do
        FactoryGirl.create_list(:asc_item, 5)
        AscItem.all.each_with_index do |item, index|
          item.position.should == index
        end
      end

    end

    describe "desc" do

      it "appends at the last position" do
        items = FactoryGirl.create_list(:desc_item, 5)
        item = Factory.create(:desc_item)
        item.position.should == items.size
      end

      it "orders items by descending position" do
        items = FactoryGirl.create_list(:desc_item, 5)
        DescItem.all.reverse.should be_contiguous.starting_at(0)
      end

    end

  end

  context "mixing options" do

    let!(:groups) { FactoryGirl.create_list(:group_with_complex_items, 5) }
    let(:start) { 1 } # Check configuration in support/models.rb

    it "manages complex items" do
      # All options are tested here (grouping, descending ordering and start position at 1)
      groups.each do |group|
        size = group.complex_items.size
        group.complex_items.reverse.should be_contiguous.starting_at(start)
      end
    end

  end

end