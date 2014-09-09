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

  factory :user, aliases: [:subject] do
    email { generate(:email) }
    participant true
  end

  factory :author, class: User do
    email { generate(:email) }
  end

  factory :token do
  end

  factory :review do
    subject
    author
    author_name { generate(:name) }
    relationship :peer
  end

  factory :reply do
    subject
    author
    author_name { generate(:name) }
    relationship :peer
  end

  factory :invitation do
    subject
    author
    author_name { generate(:name) }
    relationship :peer
    status :no_response
  end

  factory :submission do
    subject
    author
    author_name { generate(:name) }
    relationship :peer
    status :started
  end
end
