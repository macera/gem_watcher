FactoryGirl.define do

  factory :dependency do
    requirements     ' >= 3.0.0'
    provisional_name nil
  end

end
