# セキュリティfeedを登録するタスク
# rake security_feed:generate

namespace :security_feed do
  task generate: [:environment] do

    # 一般のruby gemのセキュリティフィードの取得
    path = Settings.feeds.ruby_security_ann
    content = Feedjira::Feed.fetch_and_parse(path)
    Plugin.all.each do |plugin|
      begin
        # railsは別のRSSで登録する
        next if plugin.name == 'rails'
        keyword = plugin.name
        keyword_title = keyword.titleize # web-console => Web Console
        # actionpack => Action Pack
        tmp_action = keyword.scan(/(action)(\S+)/)
        keyword_action = nil
        if tmp_action.present?
          keyword_action = "#{tmp_action.flatten[0]} #{tmp_action.flatten[1]}".titleize
        end
        # activerecord => Active Record
        tmp_active = keyword.scan(/(active)(\S+)/)
        keyword_active = nil
        if tmp_active.present?
          keyword_active = "#{tmp_active.flatten[0]} #{tmp_active.flatten[1]}".titleize
        end

        content.entries.each do |entry|
          result = nil
          if keyword_action
            result = entry.title =~ /#{keyword}|#{keyword_title}|#{keyword_action}/
          elsif keyword_active
            result = entry.title =~ /#{keyword}|#{keyword_title}|#{keyword_active}/
          else
            result = entry.title =~ /#{keyword}|#{keyword_title}/
          end

          if result
            local_entry = plugin.security_entries.where(title: entry.title).first_or_initialize

            local_entry.update_attributes!(
              content: entry.summary,
              author: entry.author,
              url: entry.url,
              published: entry.published,
              genre: 0
            )
          end
        end
      rescue => e
        CronLog.error_create(
          table_name: 'security_entry',
          content: "Gem名:#{plugin.name}, パス:#{path.to_s}, 詳細:#{e}"
        )
      end
    end

    # 一般のrailsのセキュリティフィードの取得
    begin
      path = Settings.feeds.rubyonrails_security
      content = Feedjira::Feed.fetch_and_parse(path)
      plugin = Plugin.where(name: 'rails').first

      # railsは別のRSSで登録する
      if plugin
        keyword = plugin.name
        keyword_title = keyword.titleize # web-console => Web Console
        content.entries.each do |entry|
          local_entry = plugin.security_entries.where(title: entry.title).first_or_initialize
          local_entry.update_attributes!(
            content: entry.summary,
            author: entry.author,
            url: entry.url,
            published: entry.published,
            genre: 1
          )
        end
      end
    rescue => e
      CronLog.error_create(
        table_name: 'security_entry',
        content: "Gem名:rails, パス:#{path.to_s}, 詳細:#{e}"
      )
    end

  end
end