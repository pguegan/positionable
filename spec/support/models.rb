class Group < ActiveRecord::Base
  has_many :sub_groups
end

class SubGroup < ActiveRecord::Base
  belongs_to :group
  is_positionable :parent => :group
end

class Item < ActiveRecord::Base
  is_positionable
end

class Dummy < ActiveRecord::Base
end