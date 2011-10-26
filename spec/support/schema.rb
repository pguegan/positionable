ActiveRecord::Schema.define do
  self.verbose = false

  create_table :folders, :force => true do |t|
    t.string :title
    t.integer :position
    t.timestamps
  end

  create_table :dummies, :force => true do |t|
    t.string :title
    t.timestamps
  end
end