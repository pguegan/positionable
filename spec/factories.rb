FactoryGirl.define do

  factory :group do
  	sequence(:title) { |n| "Group #{n}" }
  end

  factory :sub_group do
  	group
  	sequence(:title) { |n| "Sub Group #{n}" }
  end

  factory :item do
  	sequence(:title) { |n| "Item #{n}" }
  end

end