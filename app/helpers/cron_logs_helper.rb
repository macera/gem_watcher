module CronLogsHelper

  def table_lists
    ['project', 'plugin', 'entry', 'security_entry'].map do | table |
      [ t("activerecord.models.#{table}"), table ]
    end
  end


end