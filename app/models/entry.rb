# == Schema Information
#
# Table name: entries
#
#  id            :integer          not null, primary key
#  title         :string
#  published     :datetime
#  content       :text
#  url           :string
#  author        :string
#  plugin_id     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  major_version :integer
#  minor_version :integer
#  patch_version :string
#
# Indexes
#
#  index_entries_on_plugin_id  (plugin_id)
#

class Entry < ActiveRecord::Base
  belongs_to :plugin

  scope :newest_plugins, -> { joins(:plugin).where.not('plugins.name' => 'rails').group('entries.plugin_id').having('Max(entries.published)') }

  scope :rails_entries, -> {
    joins(:plugin).where('plugins.name' => 'rails').group('major_version', 'minor_version').having('Max(entries.published)').order('Max(entries.published) desc').limit(3)
    #joins(:plugin).where('plugins.name' => 'rails').order('entries.published desc').limit(10)
  }

  # 許可するカラムの名前をオーバーライドする
  def self.ransackable_attributes(auth_object = nil)
    %w()
  end

  def version
    if minor_version && patch_version
      "#{major_version.to_s}.#{minor_version.to_s}.#{patch_version}"
    elsif minor_version
      "#{major_version.to_s}.#{minor_version.to_s}"
    else
      "#{major_version.to_s}"
    end
  end

  # 許可する関連の配列をオーバーライドする
  # def self.ransackable_associations(auth_object = nil)
  #   reflect_on_all_associations.map { |a| a.name.to_s }
  # end

end
