# == Schema Information
#
# Table name: patched_entries
#
#  id                   :integer          not null, primary key
#  entry_id             :integer
#  security_advisory_id :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_patched_entries_on_entry_id              (entry_id)
#  index_patched_entries_on_security_advisory_id  (security_advisory_id)
#
# Foreign Keys
#
#  fk_rails_607038e33c  (entry_id => entries.id)
#  fk_rails_baaa74d7fa  (security_advisory_id => security_advisories.id)
#
# Entryとセキュリティ情報(パッチ)の中間テーブル
class PatchedEntry < ApplicationRecord
  belongs_to :entry
  belongs_to :security_advisory
end
