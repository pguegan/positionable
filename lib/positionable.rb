require "positionable/version"
require 'active_record'

module Positionable

  def self.included(base)
    base.extend(PositionableMethods)
  end

  module PositionableMethods

    def is_positionable
      include InstanceMethods

      default_scope order(:position)

      attr_protected :position

      before_create :move_to_end

      before_destroy :decrement_all_next
    end

    module InstanceMethods

      def first?
        position == 0
      end

      def last?
        position == self.class.count - 1
      end

      def next
        self.class.where(:position => position + 1).first
      end

      def all_next
        self.class.where("position > ?", position)
      end

      def previous
        self.class.where(:position => position - 1).first
      end

      def all_previous
        self.class.where("position < ?", position)
      end

      private

      def move_to_end
        self.position = self.class.count
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
