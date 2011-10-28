FactoryGirl.define do

  factory :group do
  	sequence(:title) { |n| "Group #{n}" }

    factory :group_with_sub_groups do
      after_build do |group|
        group.sub_groups = (1..5).map { Factory.build(:sub_group, :group => group) }
      end
      after_create do |group|
        group.sub_groups.each { |sub_group| sub_group.save! }
      end
    end
  end

  factory :sub_group do
  	group
  	sequence(:title) { |n| "Sub Group #{n}" }
  end

  factory :item do
  	sequence(:title) { |n| "Item #{n}" }
  end

end