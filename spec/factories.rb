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

    factory :telegram_user do
      telegram_id { rand(10000) }
      telegram_username { Faker::Internet.username }
    end

    factory :instagram_user do
      instagram_id { rand(10000) }
      instagram_username { Faker::Internet.username }
    end
  end
end
