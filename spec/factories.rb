FactoryBot.define do
  factory :match do
    searching_user { nil }
    matched_user { nil }
  end

  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    password { SecureRandom.hex }
  end
end
