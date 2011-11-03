FactoryGirl.define do

  factory :folder do
  	sequence(:title) { |n| "Folder #{n}" }

    factory :folder_with_documents do
      after_build do |folder|
        folder.documents = (1..5).map { Factory.build(:document, :folder => folder) }
      end
      after_create do |folder|
        folder.documents.each { |document| document.save! }
      end
    end
  end

  factory :document do
  	folder
  	sequence(:title) { |n| "Document #{n}" }
  end

  factory :item do
  	sequence(:title) { |n| "Item #{n}" }
  end

  factory :stuff do
    sequence(:title) { |n| "Stuff #{n}" }
  end

end