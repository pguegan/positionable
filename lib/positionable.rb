require "positionable/version"
require 'active_record'

module Positionable

  def self.included(base)
    base.extend(PositionableMethods)
  end

  module PositionableMethods

    def is_positionable
      include InstanceMethods

      before_create :move_to_end
    end

    module InstanceMethods

      def next
        self.class.where(:position => position + 1)
      end

      def previous
        self.class.where(:position => position - 1)
      end

      private

      def move_to_end
        self.position = self.class.count
      end

    end

  end

  ActiveRecord::Base.send(:include, Positionable)
end
