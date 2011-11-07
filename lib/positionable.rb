require "positionable/version"
require 'active_record'

module Positionable

  def self.included(base)
    base.extend(PositionableMethods)
  end

  module PositionableMethods

    # Calling the <tt>is_positonable</tt> method in your ActiveRecord model will inject
    # positionning capabilities. In particular, this will guarantee your records' positions
    # to be <em>contiguous</em>, ie.: there is no 'hole' between two adjacent positions.
    # 
    # Thus, you should always use the provided instance methods ("up!" and "down!")
    def is_positionable(options = {})
      include InstanceMethods

      parent_id = "#{options[:parent].to_s}_id" if options[:parent]
      start = options[:start] || 0
      order = options[:order] || :asc

      default_scope order("position #{order}")

      attr_protected :position

      before_create :move_to_end
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

      # Gives the next sibbling record, whose position is right after this record.
      def next
        sibbling(position + 1)
      end

      def all_next
        self.class.where("#{scoped_position} > ?", position)
      end

      def previous
        sibbling(position - 1)
      end

      def all_previous
        self.class.where("#{scoped_position} < ?", position)
      end

      private

      def sibbling(position)
        self.class.where("#{scoped_position} = ?", position).limit(1).first
      end

      def swap_with(other)
        self.class.transaction do
          old_position = position
          update_attribute(:position, other.position)
          other.update_attribute(:position, old_position)
        end
      end

      def move_to_end
        self.position = scoped_all.size + start
      end

      def move_to_start
        increment_all
      end

      def decrement_all_next
        self.class.transaction do
          all_next.each do |record|
            record.update_attribute(:position, record.position - 1)
          end
        end
      end

      def scoped_all
        self.class.where(scoped_condition)
      end

    end

  end

  ActiveRecord::Base.send(:include, Positionable)

end
