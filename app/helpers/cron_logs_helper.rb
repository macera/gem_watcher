module CronLogsHelper

  # 検索セレクトボックス テーブル一覧を表示する
  def table_lists
    ['project', 'plugin', 'entry', 'security_entry', 'security_advisory', 'dependency'].map do | table |
      [ t("activerecord.models.#{table}"), table ]
    end
  end


end