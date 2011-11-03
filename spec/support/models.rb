class Folder < ActiveRecord::Base
  has_many :documents
end

class Document < ActiveRecord::Base
  belongs_to :folder
  is_positionable :parent => :folder
end

class Item < ActiveRecord::Base
  is_positionable
end

class Stuff < ActiveRecord::Base
  is_positionable :start => 1
end

class Dummy < ActiveRecord::Base
end