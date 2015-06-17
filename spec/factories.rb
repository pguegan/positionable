FactoryGirl.define do

  factory :folder do
  	sequence(:title) { |n| "Folder #{n}" }

    factory :folder_with_documents do
      after(:create) do |folder|
        folder.documents = FactoryGirl.create_list(:document, 5, :folder => folder)
      end
    end
  end

  factory :document do
  	folder
  	sequence(:title) { |n| "Document #{n}" }
  end

  factory :default_item do
  	sequence(:title) { |n| "Default Item #{n}" }
  end

  factory :sub_item_1 do
    sequence(:title) { |n| "Sub-Item-1 #{n}" }
  end

  factory :sub_item_2 do
    sequence(:title) { |n| "Sub-Item-2 #{n}" }
  end

  factory :starting_at_one_item do
    sequence(:title) { |n| "Starting At One Item #{n}" }
  end

  factory :asc_item do
    sequence(:title) { |n| "Asc Item #{n}" }
  end

  factory :desc_item do
    sequence(:title) { |n| "Desc Item #{n}" }
  end

  factory :group do
    sequence(:title) { |n| "Group #{n}" }

    factory :group_with_complex_items do
      after(:create) do |group|
        group.complex_items = FactoryGirl.create_list(:complex_item, 5, :group => group)
      end
    end
  end

  factory :complex_item do
    group
    sequence(:title) { |n| "Complex Item #{n}" }
  end

  factory :stuff do
    sequence(:title) { |n| "Stuff #{n}" }
  end

  factory :skip_update_item do
    sequence(:title) { |n| "Skip Update Item #{n}" }
  end

end