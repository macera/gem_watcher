FactoryGirl.define do
  factory :version, class: ProjectVersion do
    newest     '5.0.0'
    installed  '4.2.1'
    pre         nil
    requested   nil
    project     { create(:project) }
  end
end