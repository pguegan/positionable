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

      default_scope order(:position)

      attr_protected :position

      before_create :move_to_end

      before_destroy :decrement_all_next

      if parent_id
        class_eval <<-EOV
          def scope_condition
            "#{parent_id} = " + send(:"#{parent_id}").to_s
          end
        EOV
      else
        class_eval <<-EOV
          def scope_condition
            "1 = 1"
          end
        EOV
      end
    end

    module InstanceMethods

      def first?
        position == 0
      end

      def last?
        position == self.class.where(scope_condition).size - 1
      end

      def next
        self.class.where("#{scope_condition} and position = ?", position + 1).first
      end

      def all_next
        self.class.where("#{scope_condition} and position > ?", position)
      end

      def previous
        self.class.where("#{scope_condition} and position = ?", position - 1).first
      end

      def all_previous
        self.class.where("#{scope_condition} and position < ?", position)
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

      private

      def move_to_end
        self.position = self.class.where(scope_condition).size
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
