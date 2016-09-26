# == Schema Information
#
# Table name: vulnerable_entries
#
#  id                   :integer          not null, primary key
#  entry_id             :integer
#  security_advisory_id :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_vulnerable_entries_on_entry_id              (entry_id)
#  index_vulnerable_entries_on_security_advisory_id  (security_advisory_id)
#
# Foreign Keys
#
#  fk_rails_2ce0eb3fbd  (security_advisory_id => security_advisories.id)
#  fk_rails_5531dc928b  (entry_id => entries.id)
#

# Entryとセキュリティ情報(脆弱性)の中間テーブル
class VulnerableEntry < ApplicationRecord
  belongs_to :entry
  belongs_to :security_advisory
end
