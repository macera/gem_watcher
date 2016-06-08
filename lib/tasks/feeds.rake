# feedを登録するタスク
# rake feeds:generate
namespace :feeds do

  task generate: [:environment] do

    Plugin.all.each do |plugin|
      # TODO: あとで見直す。通常のgithub以外のリポジトリ使っているgem
      if plugin.source_code_uri =~ /\/\/github.com/
        path = URI.join(plugin.source_code_uri, 'releases.atom')
        begin
          content = Feedjira::Feed.fetch_and_parse(path.to_s)
          content.entries.each do |entry|
            local_entry = plugin.entries.where(title: entry.title).first_or_initialize

            # 相対パスなので絶対パスに直す
            uri = URI.join(plugin.source_code_uri, "/")
            uri += entry.url

            local_entry.update_attributes(content: entry.content, author: entry.author, url: uri  , published: entry.published)
            p "Synced Entry - #{entry.title}"
          end
        rescue => e
          p e
          p 'feedを取得できません'
          p 'プラグイン名:' + plugin.name
          p 'パス:' + path.to_s
        end
      end
    end
  end

end
