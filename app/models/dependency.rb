# == Schema Information
#
# Table name: dependencies
#
#  id               :integer          not null, primary key
#  requirements     :string
#  provisional_name :string
#  plugin_id        :integer
#  entry_id         :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_dependencies_on_entry_id   (entry_id)
#  index_dependencies_on_plugin_id  (plugin_id)
#
# Foreign Keys
#
#  fk_rails_036d07b9a2  (entry_id => entries.id)
#  fk_rails_b2e3a2e6a1  (plugin_id => plugins.id)
#

class Dependency < ApplicationRecord
  belongs_to :entry
  belongs_to :plugin

  #after_create  :create_created_table_log

  # requirements内で最新のversionに脆弱性がある場合:errorを返す。
  # また、その最新のversionの依存gemも同様にチェックし、1以上あれば:children_errorを返す
  def alert_status
    return false unless plugin
    # requirementsで最新のversionで
    target_entry = false
    plugin.entries.order_by_version.each do |entry|
      parse_versions(requirements).each do |required_version|
        if required_version === Gem::Version.create(entry.version)
          target_entry = entry unless target_entry
          break
        end
      end
    end
    return false unless target_entry
    plugin.security_advisories.order('date desc').each do |advisory|
      if advisory.vulnerable?(target_entry.version)
        return :error
      end
    end
    target_entry.dependencies.each do |dependency|
      result = dependency.alert_status
      return :children_error if result
    end
    return false
  end

  # requirements中の最新のversionを取得する
  def latest_version_in_requirements
    return nil unless plugin
    target_entry = nil

    plugin.entries.order_by_version.each do |entry|
      parse_versions(requirements).each do |required_version|
        if required_version === Gem::Version.create(entry.version)
          target_entry = entry unless target_entry
          break
        end
      end
    end
    target_entry
  end

  # def security_entry
  #   if plugin
  #     plugin.entries.order('published desc').each do |entry|
  #       plugin.security_advisories.order('date desc').each do |advisory|
  #         if advisory.match_requirements?(requirements, entry.version)
  #           if advisory.vulnerable?(entry.version)
  #             return entry
  #           end
  #         end
  #       end
  #       entry.dependencies.each do |dependency|
  #         result = dependency.security_entry
  #         return result if result.present?
  #       end
  #     end
  #   end
  #   return false
  # end

  # そのdependency自身と子孫の脆弱性全てを返す(TODO: 重すぎる)
  # def security_entry
  #   alert_enries = []
  #   if plugin
  #     plugin.entries.order('published desc').each do |entry|
  #       plugin.security_advisories.order('date desc').each do |advisory|
  #         if advisory.match_requirements?(requirements, entry.version)
  #           if advisory.vulnerable?(entry.version)
  #             return [entry]
  #           end
  #           entry.dependencies.each do |dependency|
  #             result = dependency.security_entry
  #             alert_enries << result.first if result.present?
  #           end
  #         end
  #       end
  #     end
  #   end
  #   alert_enries.uniq
  # end

  # 依存関係作成ログ
  # def create_created_table_log
  #   plugin_name = plugin ? plugin.name : provisional_name
  #   CronLog.success_table(self.class.to_s.underscore, "#{entry.title}のDependencies(#{plugin_name})", :create)
  # end

  # 削除ログ
  # def create_destroyed_table_log
  #   CronLog.success_table(self.class.to_s.underscore, "#{entry.title}のDependencies(#{plugin.name})", :delete)
  # end

  private

  def parse_versions(string)
    versions = string.to_s.split(':')
    Array(versions).map do |version|
      Gem::Requirement.new(*version.split(', '))
    end
  end

end
