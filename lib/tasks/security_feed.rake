namespace :security_feed do
  task generate: [:environment] do

    # 一般のruby gemのセキュリティフィードの取得
    path = "https://groups.google.com/forum/feed/ruby-security-ann/topics/atom.xml?num=50"
    content = Feedjira::Feed.fetch_and_parse(path)
    Plugin.all.each do |plugin|
      # railsは別のRSSで登録する
      next if plugin.name == 'rails'
      keyword = plugin.name
      keyword_title = keyword.titleize # web-console => Web Console
      content.entries.each do |entry|
        if entry.title =~ /#{keyword}|#{keyword_title}/
          local_entry = plugin.security_entries.where(title: entry.title).first_or_initialize

          local_entry.update_attributes(content: entry.summary, author: entry.author, url: entry.url, published: entry.published, genre: 0)
          p "Synced Entry - #{entry.title}"
        end
      end
    end

    # 一般のrailsのセキュリティフィードの取得
    path = "https://groups.google.com/forum/feed/rubyonrails-security/topics/atom.xml?num=50"
    content = Feedjira::Feed.fetch_and_parse(path)
    plugin = Plugin.where(name: 'rails').first

    # railsは別のRSSで登録する
    keyword = plugin.name
    keyword_title = keyword.titleize # web-console => Web Console
    content.entries.each do |entry|
      local_entry = plugin.security_entries.where(title: entry.title).first_or_initialize
      local_entry.update_attributes(content: entry.summary, author: entry.author, url: entry.url, published: entry.published, genre: 1)
      p "Synced Entry - #{entry.title}"
    end

  end
end