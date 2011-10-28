ActiveRecord::Schema.define do
  self.verbose = false

  create_table :groups, :force => true do |t|
    t.string :title
    t.timestamps
  end

  create_table :sub_groups, :force => true do |t|
    t.integer :group_id
    t.string :title
    t.integer :position
    t.timestamps
  end

  create_table :items, :force => true do |t|
    t.string :title
    t.integer :position
    t.timestamps
  end

  create_table :dummies, :force => true do |t|
    t.string :title
    t.timestamps
  end
end