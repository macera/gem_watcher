# feedを登録するタスク
# rake feeds:generate
namespace :feeds do

  # rubygemorg リリースフィード取得
  task generate: [:environment] do

    Plugin.all.each do |plugin|
      begin
        path = URI.join("#{Settings.feeds.rubygem}#{plugin.name}/versions.atom")
        content = Feedjira::Feed.fetch_and_parse(path.to_s)
        content.entries.each do |entry|
          # beta版等は除く
          next if entry.title =~ /beta|rc|racecar|pre/

          # 0.0.0
          version = entry.title.scan(/\S+\s\((\d+)\.(\d+)\.(\S+)\)/).first
          # 0.0
          unless version
            version = entry.title.scan(/\S+\s\((\d+)\.(\d+)\)/).first
          end
          # 0
          unless version
            version = entry.title.scan(/\S+\s\((\d+)\)/).first
          end

          local_entry = plugin.entries.where(title: entry.title).first_or_initialize
          local_entry.update_attributes!(
            content: entry.content,
            author: entry.author,
            url: entry.entry_id,
            published: entry.published,
            major_version: version[0],
            minor_version: version[1],
            patch_version: version[2]
          )
        end
      rescue => e
        CronLog.error_create(
          table_name: 'entry',
          content: "Gem名:#{plugin.name}, パス:#{path.to_s}, 詳細:#{e}"
        )
      end
    end
  end

  # Github リリースフィード取得
  # task generate_for_github: [:environment] do

  #   Plugin.all.each do |plugin|
  #     # TODO: あとで見直す。
  #     if plugin.source_code_uri =~ /\/\/github.com/
  #       begin
  #         path = URI.join(plugin.source_code_uri, 'releases.atom')
  #         content = Feedjira::Feed.fetch_and_parse(path.to_s)
  #         content.entries.each do |entry|
  #           local_entry = plugin.entries.where(title: entry.title).first_or_initialize

  #           # 相対パスなので絶対パスに直す
  #           uri = URI.join(plugin.source_code_uri, "/")
  #           uri += entry.url

  #           local_entry.update_attributes!(content: entry.content, author: entry.author, url: uri, published: entry.published)
  #         end
  #       rescue => e
  #         CronLog.error_create(
  #           table_name: 'entries',
  #           content: "プラグイン名:#{plugin.name}, パス:#{path.to_s}, 詳細:#{e}"
  #         )
  #       end
  #     end
  #   end
  # end

end
