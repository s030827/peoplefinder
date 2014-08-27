FactoryGirl.define do
  sequence :email do |n|
    "example.user.%d@example.com" % n
  end

  sequence :password do |n|
    "Insecure%03d" % n
  end

  sequence :name do |n|
    "Name-%04d" % n
  end

  factory :user do
    email { generate(:email) }
  end

  factory :token do
  end

  factory :review do
    subject
    author_name { generate(:name) }
    author_email { generate(:email) }
  end

  factory :review_token, class: Token do
    review
  end

  factory :subject, class: User do
    email { generate(:email) }
  end
end
