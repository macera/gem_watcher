# == Schema Information
#
# Table name: cron_logs
#
#  id         :integer          not null, primary key
#  table_name :string
#  content    :text
#  state      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# cronのログ保存用テーブル
class CronLog < ActiveRecord::Base

  enum state: {
    success: 0,
    error:   1
  }
  def self.error_create(attributes={})
    create({ state: states[:error] }.merge(attributes))
    logger.error attributes[:content]
  end

  def self.success_create(attributes={})
    create({ state: states[:success] }.merge(attributes))
    logger.error attributes[:content]
  end

  def self.success_create_table(table, name)
    create({
      state: states[:success],
      table_name: table ,
      content: "新しい#{ I18n.t "activerecord.models.#{table}" }「#{ name }」が作成されました。"
    })
  end


end
