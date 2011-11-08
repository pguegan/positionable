class Folder < ActiveRecord::Base
  has_many :documents
end

class Document < ActiveRecord::Base
  belongs_to :folder
  is_positionable :group => :folder
end

class Item < ActiveRecord::Base
end

class ItemDefault < Item
  is_positionable
end

class ItemStartingAtOne < Item
  is_positionable :start => 1
end

class ItemAsc < Item
  is_positionable :order => :asc
end

class ItemDesc < Item
  is_positionable :order => :desc
end

class Dummy < ActiveRecord::Base
end