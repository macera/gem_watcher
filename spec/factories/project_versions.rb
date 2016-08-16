FactoryGirl.define do

  factory :project_version do
    newest     '5.0.0'
    installed  '4.2.1'
    pre         nil
    requested   nil
    project     { create(:project) }
    plugin      { create(:plugin) }
    described   true
  end

  factory :version, class: ProjectVersion do
    newest     '5.0.0'
    installed  '4.2.1'
    pre         nil
    requested   nil
    project     { create(:project) }
    plugin      { create(:plugin) }
    described   true
  end

  factory :vulnerability_version, class: ProjectVersion do
    newest     '1.6.8'
    installed  '1.6.7'
    pre         nil
    requested   nil
    project     { create(:project) }
    plugin      { create(:plugin) }
    described   true
  end

  factory :project_version_attributes, class: ProjectVersion do
    plugin_name 'rails'
    installed  '2.3.5'
    requested   '= 2.3.5'
  end
end