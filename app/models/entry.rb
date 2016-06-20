# == Schema Information
#
# Table name: entries
#
#  id         :integer          not null, primary key
#  title      :string
#  published  :datetime
#  content    :text
#  url        :string
#  author     :string
#  plugin_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_entries_on_plugin_id  (plugin_id)
#

class Entry < ActiveRecord::Base
  belongs_to :plugin

  scope :newest_plugins, -> { group('entries.plugin_id').having('Max(entries.published)') }

  # 許可するカラムの名前をオーバーライドする
  def self.ransackable_attributes(auth_object = nil)
    %w()
  end

  # 許可する関連の配列をオーバーライドする
  # def self.ransackable_associations(auth_object = nil)
  #   reflect_on_all_associations.map { |a| a.name.to_s }
  # end

end
