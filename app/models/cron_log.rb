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
    create!({ state: states[:error] }.merge(attributes))
    logger.error attributes[:content]
  end

  def self.success_create(attributes={})
    create!({ state: states[:success] }.merge(attributes))
    logger.error attributes[:content]
  end

  def self.success_table(table, name, action)
    case action
    when :create; action_name = '作成'
    when :update; action_name = '更新'
    when :delete; action_name = '削除'
    end
    create!({
      state: states[:success],
      table_name: table ,
      content: "#{ I18n.t "activerecord.models.#{table}" }「#{ name }」が#{action_name}されました。"
    })
  end


end
