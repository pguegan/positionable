require "positionable/version"
require 'active_record'

module Positionable

  def self.included(base)
    base.extend(PositionableMethods)
  end

  module PositionableMethods

    def is_positionable(options = {})
      include InstanceMethods

      parent_id = "#{options[:parent].to_s}_id" if options[:parent]
      start = options[:start] || 0

      default_scope order(:position)

      attr_protected :position

      before_create :move_to_end

      after_destroy :decrement_all_next

      if parent_id
        class_eval <<-EOV
          def scoped_condition
            "#{parent_id} = " + send(:"#{parent_id}").to_s
          end
          def scoped_position
            "#{parent_id} = " + send(:"#{parent_id}").to_s + " and position"
          end
        EOV
      else
        class_eval <<-EOV
          def scoped_condition
            ""
          end
          def scoped_position
            "position"
          end
        EOV
      end

      if start
        class_eval <<-EOV
          def start
            #{start}
          end
        EOV
      end

    end

    module InstanceMethods

      def first?
        position == start
      end

      def last?
        position == self.class.where(scoped_condition).size + start - 1
      end

      def up!
        unless first?
          previous.update_attribute(:position, position)
          update_attribute(:position, position - 1)
        end
      end

      def down!
        unless last?
          self.next.update_attribute(:position, position)
          update_attribute(:position, position + 1)
        end
      end

      def next
        self.class.where("#{scoped_position} = ?", position + 1).first
      end

      def all_next
        self.class.where("#{scoped_position} > ?", position)
      end

      def previous
        self.class.where("#{scoped_position} = ?", position - 1).first
      end

      def all_previous
        self.class.where("#{scoped_position} < ?", position)
      end

      private

      def move_to_end
        self.position = self.class.where(scoped_condition).size + start
      end

      def decrement_all_next
        all_next.each do |record|
          record.update_attribute(:position, record.position - 1)
        end
      end

    end

  end

  ActiveRecord::Base.send(:include, Positionable)

end
