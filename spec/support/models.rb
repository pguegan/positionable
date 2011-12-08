class Folder < ActiveRecord::Base
  has_many :documents
end

class Document < ActiveRecord::Base
  belongs_to :folder
  is_positionable :scope => :folder
  attr_accessible :position, :folder_id
end

class Item < ActiveRecord::Base
end

class DefaultItem < Item
  is_positionable
end

class StartingAtOneItem < Item
  is_positionable :start => 1
end

class AscItem < Item
  is_positionable :order => :asc
end

class DescItem < Item
  is_positionable :order => :desc
end

class Group < ActiveRecord::Base
  has_many :complex_items
end

class ComplexItem < Item
  belongs_to :group
  is_positionable :scope => :group, :order => :desc, :start => 1
  attr_accessible :position, :group_id
end

class Dummy < ActiveRecord::Base
end