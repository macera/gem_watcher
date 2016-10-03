FactoryGirl.define do

  factory :dependency do
    requirements     ' >= 3.0.0'
    provisional_name nil

    after(:create) do |dependency|
      if dependency.plugin
        create(:latest_entry_in_requirement,
                entry:       dependency.latest_version_in_requirements,
                dependency:  dependency)
      end
    end
  end

end
