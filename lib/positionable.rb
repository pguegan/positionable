require "positionable/version"
require 'active_record'

# <b>Positionable</b> is a library which provides contiguous positionning capabilities to your
# ActiveRecord models. This module is designed to be an ActiveRecord extension.
#
# Calling the <tt>is_positionable</tt> method in your ActiveRecord model will inject
# positionning capabilities. In particular, this will guarantee your records' positions
# to be <em>contiguous</em>, ie.: there is no 'hole' between two adjacent positions.
#
# You should always use the provided instance methods (<tt>up!</tt> and <tt>down!</tt>) to move
# or reorder your records. In order to keep contiguous position integrity, it is discouraged to
# directly assign a record's position.
#
# Additional methods are available to query your model: check if this the <tt>last?</tt> or
# <tt>first?</tt> of its own group, retrieve the <tt>previous</tt> or the <tt>next</tt> records
# according to their positions, etc.
module Positionable

  def self.included(base)
    base.extend(PositionableMethods)
  end

  module PositionableMethods

    # Makes this model positionable.
    # 
    #   class Item < ActiveRecord::Base
    #     is_positionable
    #   end
    #
    # Maybe your items are grouped (typically with a +belongs_to+ association). In this case, 
    # you'll want to restrict the position in each group by declaring the +:parent+ option:
    #
    #   class Folder < ActiveRecord::Base
    #     has_many :items
    #   end
    #
    #   class Item < ActiveRecord::Base
    #     belongs_to :folder
    #     is_positionable :parent => :folder
    #   end
    #
    # By default, position starts by zero. But you may want to change this at the model level,
    # for instance by starting at one (which seems more natural for some people):
    # 
    #   class Item < ActiveRecord::Base
    #     is_positionable :start => 1
    #   end
    #
    # To make new records to appear at first position, the default ordering can be changed as
    # follows:
    #
    #   class Item < ActiveRecord::Base
    #     is_positionable :order => :desc
    #   end
    def is_positionable(options = {})
      include InstanceMethods

      parent_id = "#{options[:parent].to_s}_id" if options[:parent]
      start = options[:start] || 0
      order = options[:order] || :asc

      default_scope order("position #{order}")

      attr_protected :position

      before_create :move_to_bottom
      after_destroy :decrement_all_next

      if parent_id
        class_eval <<-RUBY
          def scoped_condition
            "#{parent_id} = " + send(:"#{parent_id}").to_s
          end
          def scoped_position
            "#{parent_id} = " + send(:"#{parent_id}").to_s + " and position"
          end
        RUBY
      else
        class_eval <<-RUBY
          def scoped_condition
            ""
          end
          def scoped_position
            "position"
          end
        RUBY
      end

      class_eval <<-RUBY
        def start
          #{start}
        end
      RUBY
    end

    module InstanceMethods

      # Tells whether this record is the first one (of his group, if any).
      def first?
        position == start
      end

      # Tells whether this record is the last one (of his group, if any).
      def last?
        position == scoped_all.size + start - 1
      end

      # Swaps this record position with his previous sibbling, unless this record is the first one.
      def up!
        unless first?
          swap_with(previous)
        end
      end

      # Swaps this record position with his next sibbling, unless this record is the last one.
      def down!
        unless last?
          swap_with(self.next)
        end
      end

      # The next sibbling record, whose position is right after this record.
      def next
        at(position + 1)
      end

      # All the next records, whose positions are greater than this record. Records
      # are ordered by their respective positions, depending on the <tt>order</tt> option
      # provided to <tt>is_positionable</tt>
      def all_next
        self.class.where("#{scoped_position} > ?", position)
      end

      # Gives the next sibbling record, whose position is right before this record.
      def previous
        at(position - 1)
      end

      # All the next records, whose positions are smaller than this record. Records
      # are ordered by their respective positions, depending on the <tt>order</tt> option
      # provided to <tt>is_positionable</tt> (ascending by default).
      def all_previous
        self.class.where("#{scoped_position} < ?", position)
      end

    private

      # The record at the provided position.
      def at(position)
        self.class.where("#{scoped_position} = ?", position).limit(1).first
      end

      # Swaps this record's position with the other provided record.
      def swap_with(other)
        self.class.transaction do
          old_position = position
          update_attribute(:position, other.position)
          other.update_attribute(:position, old_position)
        end
      end

      # Moves this record at the bottom.
      def move_to_bottom
        self.position = scoped_all.size + start
      end

      # Decrements the position of all the next sibbling record of this record.
      def decrement_all_next
        self.class.transaction do
          all_next.each do |record|
            record.update_attribute(:position, record.position - 1)
          end
        end
      end

      # All the records that belong to same parent (if any) of this record (including itself).
      def scoped_all
        self.class.where(scoped_condition)
      end

    end

  end

  ActiveRecord::Base.send(:include, Positionable)

end
