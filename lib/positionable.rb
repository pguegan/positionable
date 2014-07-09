require "positionable/version"
require 'active_record'

# <b>Positionable</b> is a library which provides contiguous positionning capabilities to your
# ActiveRecord models. This module is designed to be an ActiveRecord extension.
#
# Calling the <tt>is_positionable</tt> method in your ActiveRecord model will inject
# positionning capabilities. In particular, this will guarantee your records' positions
# to be <em>contiguous</em>, ie.: there is no 'hole' between two adjacent positions.
#
# Positionable has a strong management of records that belong to a group (a.k.a. scope). When a
# record is moved whithin its scope, or from a scope to another, other impacted records are 
# also reordered accordingly.
#
# You can use the provided instance methods (<tt>up!</tt>, <tt>down!</tt> or <tt>move_to</tt>)
# to move or reorder your records, whereas it is possible to update the position <em>via</em>
# mass-assignement. In particular, <tt>update_attributes({:position => new_position})</tt> will
# trigger some ActiveRecord callbacks in order to maintain positions' contiguity.
#
# Additional methods are available to query your model: check if this the <tt>last?</tt> or
# <tt>first?</tt> of its own scope, retrieve the <tt>previous</tt> or the <tt>next</tt> records
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
    # you'll want to restrict the position in each group by declaring the +:scope+ option:
    #
    #   class Folder < ActiveRecord::Base
    #     has_many :items
    #   end
    #
    #   class Item < ActiveRecord::Base
    #     belongs_to :folder
    #     is_positionable :scope => :folder
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

      scope_id_attr = "#{options[:scope].to_s}_id" if options[:scope]
      start = options[:start] || 0
      order = options[:order] || :asc

      default_scope { order("#{ActiveRecord::Base.connection.quote_table_name self.table_name}.#{ActiveRecord::Base.connection.quote_column_name 'position'} #{order}") }

      before_create :add_to_bottom
      before_update :update_position
      after_destroy :decrement_all_next

      if scope_id_attr
        class_eval <<-RUBY

          def scope_id
            send(:"#{scope_id_attr}")
          end

          # Gives the range of available positions for this record, whithin the provided scope.
          # If no scope is provided, then it takes the record's current scope by default.
          # If this record is new and no scope can be retrieved, then a <tt>RangeWithoutScopeError</tt>
          # is raised.
          def range(scope = nil)
            raise RangeWithoutScopeError if new_record? and scope.nil? and scope_id.nil?
            # Does its best to retrieve the target scope...
            target_scope_id = scope.nil? ? scope_id : scope.id
            # Number of records whithin the target scope
            count = if target_scope_id.nil?
              self.class.where("#{scope_id_attr} IS NULL").count
            else
              self.class.where("#{scope_id_attr} = ?", target_scope_id).count
            end
            # An additional position is available if this record is new, or if it's moved to another scope
            if new_record? or target_scope_id != scope_id
              (start..(start + count))
            else
              (start..(start + count - 1))
            end
          end

        private

          def scoped_condition
            if scope_id.nil?
              "#{scope_id_attr} is null"
            else
              "#{scope_id_attr} = " + scope_id.to_s
            end
          end

          def scoped_position
            scoped_condition + " and position"
          end

          def scope_changed?
            send(:"#{scope_id_attr}_changed?")
          end

          def scope_id_was
            send(:"#{scope_id_attr}_was")
          end

          def scoped_condition_was
            if scope_id_was.nil?
              "#{scope_id_attr} IS NULL"
            else
              "#{scope_id_attr} = " + scope_id_was.to_s
            end
          end

          def scoped_position_was
            scoped_condition_was + " and position"
          end

        RUBY
      else
        class_eval <<-RUBY

          # Gives the range of available positions for this record.
          def range
            if new_record?
              (start..(bottom + 1))
            else
              (start..bottom)
            end
          end

        private

          def scope_changed?
            false
          end

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

      # Tells whether this record is the first one (of his scope, if any).
      def first?
        position == start
      end

      # Tells whether this record is the last one (of his scope, if any).
      def last?
        position == bottom
      end

      # Swaps this record position with his previous sibling, unless this record is the first one.
      def up!
        swap_with(previous) unless first?
      end

      # Swaps this record position with his next sibling, unless this record is the last one.
      def down!
        swap_with(self.next) unless last?
      end

      # Moves this record at the given position, and updates positions of the impacted sibling
      # records accordingly. If the new position is out of range, then the record is not moved.
      def move_to(new_position)
        if range.include? new_position
          reorder(position, new_position)
          update_column(:position, new_position)
        end
      end

      # The next sibling record, whose position is right after this record.
      def next
        at(position + 1)
      end

      # All the next records, whose positions are greater than this record. Records
      # are ordered by their respective positions, depending on the <tt>order</tt> option
      # provided to <tt>is_positionable</tt>.
      def all_next
        self.class.where("#{scoped_position} > ?", position)
      end

      # All the next records <em>of the old scope</em>, whose positions are greater 
      # than this record before it was moved from its old record.
      def all_next_was
        self.class.where("#{scoped_position_was} > ?", position_was)
      end

      # Gives the next sibling record, whose position is right before this record.
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

      # The position of the last record.
      def bottom
        scoped_all.size + start - 1
      end

      # Finds the record at the given position.
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

      # All the records that belong to same scope (if any) of this record (including itself).
      def scoped_all
        # The range is shared among all subclasses of the base class, which directly extends ActiveRecord::Base
        self.class.base_class.where(scoped_condition)
      end

      # Reorders records between provided positions, unless the destination position is out of range.
      def reorder(from, to)
        if to > from
          shift, positions_range = -1, ((from + 1)..to)
        elsif scope_changed?
          # When scope changes, it actually inserts this record in the new scope
          # All next siblings (from new position to bottom) have to be staggered
          shift, positions_range = 1, (to..bottom)
        else
          shift, positions_range = 1, (to..(from - 1))
        end
        scoped_all.where(position: positions_range).update_all(['position = position + ?', shift])
      end

      # Reorders records between old and new position (and old and new scope).
      def update_position
        if scope_changed?
          decrement(all_next_was)
          if range.include?(position)
            reorder(position_was, position)
          else
            add_to_bottom
          end
        else
          if range.include?(position)
            reorder(position_was, position)
          else
            self.position = position_was # Keep original position
          end
        end
      end

      # Adds this record to the bottom.
      def add_to_bottom
        self.position = bottom + 1
      end

      # Decrements the position of all the next sibling records of this record.
      def decrement_all_next
        decrement(all_next)
      end

      # Decrements the position of all the provided records.
      def decrement(records)
        records.update_all(['position = position - 1'])
      end

    end

  end

  class RangeWithoutScopeError < StandardError
  end

  ActiveRecord::Base.send(:include, Positionable)

end
